import fs from 'fs'
import PEG from 'pegjs'

let parser = PEG.buildParser(fs.readFileSync('c.pegjs').toString())
let data = fs.readFileSync(process.argv[2]).toString()
let output = {}

function iterate (data) {
  if (data.hasOwnProperty('type')) {
    switch (data.type) {
      case 'enum':
        if (!data.attributes) {
          break
        }
        for (let attribute of data.attributes) {
          output[attribute.identifier] = attribute.value
        }
        break
      case 'assign':
        output[data.identifier] = data.value
        break
      case 'attribute':
        return iterate(data.identifier)
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
console.log(JSON.stringify(output, null, ' '))
