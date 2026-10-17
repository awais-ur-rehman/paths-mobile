import importlib.util, pathlib, unittest, sys
path=pathlib.Path(__file__).resolve().parents[2]/'tools/generate_api_contract.py'
spec=importlib.util.spec_from_file_location('generator',path)
module=importlib.util.module_from_spec(spec)
args=sys.argv;sys.argv=[str(path)]
try:spec.loader.exec_module(module)
finally:sys.argv=args
class ContractGeneratorTest(unittest.TestCase):
 def test_boolean_terms_and_string_enum_are_typed(self):
  contract={'info':{'version':'1.1.0'},'components':{'schemas':{'Signup':{'type':'object','required':['terms','purpose'],'properties':{'terms':{'type':'boolean','enum':[True]},'purpose':{'type':'string','enum':['signup','reset']}}}}}}
  result=module.generate(contract,b'fixture');self.assertIn('final bool terms',result);self.assertIn('Map<String, dynamic> toJson()',result);self.assertNotIn('[True]',result)
 def test_optional_nullable_and_number_fields_have_precise_guards(self):
  schema={'type':'object','required':['age','reason'],'properties':{'age':{'type':'number'},'reason':{'type':'string','nullable':True},'back':{'type':'string'}}}
  result=module.generate({'info':{'version':'1'},'components':{'schemas':{'X':schema}}},b'')
  self.assertIn('final num age',result);self.assertIn('final String? reason',result);self.assertIn('this.back',result)
  self.assertIn("if (back != null) 'back': back",result);self.assertIn('reason != null && reason is! String',result)
 def test_required_arrays_of_strings_and_references_are_typed(self):
  schemas={'Child':{'type':'object','required':['id'],'properties':{'id':{'type':'string'}}},'Batch':{'type':'object','required':['items','ids'],'properties':{'items':{'type':'array','items':{'$ref':'#/components/schemas/Child'}},'ids':{'type':'array','items':{'type':'string'}}}}}
  result=module.generate({'info':{'version':'1.4.0'},'components':{'schemas':schemas}},b'')
  self.assertIn('List<Child>',result);self.assertIn('Child.fromJson(item)',result);self.assertIn('item.toJson()',result);self.assertIn('List<String>',result)
 def test_nested_schema_fails_explicitly(self):
  with self.assertRaises(ValueError):module.generate({'info':{'version':'1'},'components':{'schemas':{'X':{'type':'object','properties':{'x':{'type':'object'}}}}}},b'')
if __name__=='__main__':unittest.main()
