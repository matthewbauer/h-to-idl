import fs from 'fs'
import PEG from 'pegjs'
import Handlebars from 'handlebars'
import math from 'mathjs'
import _ from 'lodash'

let parser = PEG.buildParser(fs.readFileSync('c.pegjs').toString())

let data = fs.readFileSync(process.argv[2]).toString()

let _defs = {}
let enums = {}
let structs = {}
let funcs = {}
let typedefs = {}

function resolve_type (type) {
  if (typeof type !== 'string') {
    return type
  }
  type = type.replace('unsigned', 'unsigned long')
  type = type.replace('size_t', 'unsigned long')
  type = type.replace('size_t', 'unsigned long')
  type = type.replace('const', '')
  type = type.replace('char *', 'DOMString')
  return type
}

function iterate (data) {
  if (data.hasOwnProperty('type')) {
    switch (data.type) {
      case 'struct':
        let struct = {}
        if (data.attributes) {
          for (let attribute of data.attributes) {
            struct[attribute.identifier] = resolve_type(attribute.specifier)
          }
        }
        structs[data.identifier] = struct
        break
      case 'enum':
        let _enum = {}
        for (let attribute of data.attributes) {
          if (!attribute.value || attribute.value === 'INT_MAX') {
            continue
          }
          _enum[attribute.identifier] = attribute.value
        }
        enums[data.identifier] = _enum
        break
      case 'assign':
        _defs[data.identifier] = data.value
        break
      case 'attribute':
        if (data.specifier[0] === 'typedef') {
        } else if (data.identifier.type === 'args') {
          let identifier = data.specifier[data.specifier.length - 1]
          let type = data.specifier.slice(1, data.specifier.length - 1).filter(function (val) {return val !== '*'}).join(' ')
          type = resolve_type(type)
          let args = []
          for (let parameters of data.identifier.value) {
            let types = []
            for (let type of parameters.value) {
              if (type === '*') {
                continue
              }
              if (type.type) {
                types.push(type.identifier)
              } else {
                if (type === 'const') {
                  continue
                }
                types.push(type)
              }
            }
            if (types[0] === 'void') {
              break
            }
            if (types.length === 1) {
              types.push('arg')
            }
            args.push(resolve_type(types.join(' ')))
          }
          type = resolve_type(type)
          funcs[identifier] = {
            type,
            args: args.join(', ')
          }
        } else {
          return iterate(data.identifier)
        }
        break
      default:
        break
    }
    if (data.value) {
      return iterate(data.value)
    }
  }
  if (Array.isArray(data)) {
    return data.map(iterate)
  }
}

iterate(parser.parse(data))

let defs = {}
_.each(_defs, function (def, key) {
  try {
    if (def && key !== 'true' && def !== '') {
      let val = math.eval(def, _defs)
      if (val && Number.isInteger(val)) {
        defs[key] = val
      }
    }
  } catch (e) {
  }
})

let template = Handlebars.compile(fs.readFileSync('idl.hbs').toString())
console.log(template({enums, structs, funcs, typedefs, defs}))
