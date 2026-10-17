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
 def test_unsupported_optional_schema_fails_explicitly(self):
  with self.assertRaises(ValueError):module.generate({'info':{'version':'1'},'components':{'schemas':{'X':{'type':'object','properties':{'x':{'type':'string'}}}}}},b'')
if __name__=='__main__':unittest.main()
