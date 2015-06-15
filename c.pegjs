start
  = __ declarations:declaration_list __ {return declarations}

__
  = (comment / whitespace / eol)*

declaration_list
  = l:declaration __ r:declaration_list {return [l].concat(r)}
  / d:declaration {return [d]}

pragma_val
  = (!(eol/comment) character)* {return text()}

declaration
  = 'extern' __ string __ '{' __ t:declaration_list __ '}' {return t}
  / '#' __ 'define' __ identifier:identifier __ value:pragma_val {return {type: 'assign', identifier: identifier, value: value}}
  / '#' pragma:pragma_val {return {type: 'pragma', value: pragma}}
  / l:declaration_specifiers __ r:declarator __ ';' {return {type: 'attribute', identifier: r, specifier: l}}
  / l:declaration_specifiers __ ';' {return {type: 'attribute', identifier: l[l.length-1], specifier: l.slice(0, l.length - 1).join(' ')}}

declaration_specifiers
  = l:type_qualifier __ r:declaration_specifiers {return [l].concat(r)}
  / t:type_qualifier {return [t]}
  / l:type_specifier __ r:declaration_specifiers {return [l].concat(r)}
  / t:type_specifier {return [t]}
  / l:pointer __ r:declaration_specifiers {return [l].concat(r)}
  / t:pointer {return [t]}
  / l:storage_class_specifier __ r:declaration_specifiers {return [l].concat(r)}
  / t:storage_class_specifier {return [t]}

storage_class_specifier
	= 'typedef'
	/ 'extern'
	/ 'static'
	/ 'auto'
	/ 'register'

abstract_declarator
  = '(' __ p:pointer __ t:type_specifier __ ')' __ d:abstract_declarator {return [p, t].concat(d)}
  / '(' __ v:parameter_list __ ')' {return v}

pointer
	= '*'
	/ '*' __ pointer

type_specifier
  = struct_or_union_specifier
	/ enum_specifier
  / identifier

struct_or_union_specifier
  = struct_or_union __ identifier:identifier __ '{' __ value:declaration_list __ '}' {return {type: 'struct', identifier: identifier, attributes: value}}
	/ struct_or_union __ '{' __ value:declaration_list __ '}' {return {type: 'struct', attributes: value}}
	/ struct_or_union __ identifier:identifier {return {type: 'struct', identifier: identifier}}

struct_or_union
	= 'struct'
	/ 'union'

enum_specifier
  = 'enum' __ identifier:identifier __ '{' __ value:enumerator_list __ '}' {return {type: 'enum', identifier: identifier, attributes: value}}
	/ 'enum' __ '{' __ value:enumerator_list __ '}' {return {type: 'enum', attributes: value}}
	/ 'enum' __ identifier:identifier {return {type: 'enum', identifier: identifier}}

enumerator_list
	= l:enumerator __ ',' __ r:enumerator_list {return r.concat(l)}
  / l:enumerator {return [l]}

enumerator
	= identifier:identifier __ '=' __ value:constant {return {type: 'assign', identifier: identifier, value: value}}
  / identifier:identifier __ '=' __ value:identifier {return {type: 'assign', identifier: identifier, value: value}}
  / identifier:identifier {return {type: 'assign', identifier: identifier}}

type_qualifier
	= 'const'
	/ 'volatile'

declarator
  = direct:direct_declarator {return direct}
  / abstract:abstract_declarator {return {type: 'args', value: abstract}}
  / direct:direct_declarator __ abstract:abstract_declarator {return [direct].concat(abstract)}

direct_declarator
  = identifier {return text()}

parameter_list
	= l:parameter_declaration __ ',' __ r:parameter_list {return r.concat(l)}
  / l:parameter_declaration __ ',' __ '...' {return [l, {type: 'parameter', value: '...'}]}
  / l:parameter_declaration {return [l]}

parameter_declaration
	= specs:declaration_specifiers __ r:declarator {return {type: 'parameter', identifier: r, value: specs}}
	/ specs:declaration_specifiers {return {type: 'parameter', value: specs}}

string
  = '"' s:(!'"' character)* '"'

constant
  = '0x' [0-9a-f]+ {return parseInt(text(), 16)}
  / [0-9]+ {return parseInt(text(), 10)}

identifier
  = [a-zA-Z_0-9]+ {return text()}

whitespace
  = '\t' / ' '

eol
  = '\n' / '\r' / '\r\n'

comment
  = '//' comment:(!eol character)* {return {type: 'comment', comment: comment}}
  / '/*' comment:(!'*/' character)* '*/' {return {type: 'comment', comment: comment}}

character
  = .
