"""Execute production endpoint guards from both native platforms, using cached tools."""
from pathlib import Path
import os, subprocess, tempfile, unittest
ROOT=Path(__file__).resolve().parents[2]
class NativeUploadPolicyTest(unittest.TestCase):
 def test_native_endpoint_guards(self):
  kotlin=ROOT/'android/app/src/main/kotlin/com/paths/mobile/location/UploadEndpointPolicy.kt'
  swift=ROOT/'ios/Runner/Location/UploadEndpointPolicy.swift'
  self.assertTrue(kotlin.exists() and swift.exists(),'native upload endpoint policy is missing')
  cases=[('https://api.example.invalid/v1/locations',False,True),('http://127.0.0.1:8080/v1/locations',True,True),('http://127.0.0.1:8080/v1/locations',False,False),('http://api.example.invalid/v1/locations',True,False),('https://api.example.invalid/v1/locations?token=secret',True,False),('https://user@api.example.invalid/v1/locations',True,False),('https://api.example.invalid/v1/locations#fragment',True,False),('https://api.example.invalid/other',True,False)]
  cache=Path.home()/'.gradle/caches/modules-2/files-2.1'
  compiler=[]
  for group,artifact,version in [('org.jetbrains.kotlin','kotlin-compiler-embeddable','2.4.0'),('org.jetbrains.kotlin','kotlin-stdlib','2.4.0'),('org.jetbrains.kotlin','kotlin-reflect','2.2.21'),('org.jetbrains.kotlin','kotlin-script-runtime','2.4.0'),('org.jetbrains.kotlinx','kotlinx-coroutines-core-jvm','1.10.2'),('org.jetbrains','annotations','13.0')]:compiler+=list((cache/group/artifact/version).glob('*/*.jar'))
  stdlib=list((cache/'org.jetbrains.kotlin/kotlin-stdlib/2.4.0').glob('*/*.jar'))
  self.assertTrue(compiler and stdlib,'cached Kotlin compiler is required')
  with tempfile.TemporaryDirectory(prefix='paths-endpoint-') as temp:
   folder=Path(temp);probe=folder/'Probe.kt'
   probe.write_text('package com.paths.mobile.location\nfun main(){\n'+'\n'.join(f'check(UploadEndpointPolicy.valid("{url}",{str(debug).lower()}) == {str(expected).lower()})' for url,debug,expected in cases)+'\n}')
   subprocess.run(['java','-cp',os.pathsep.join(map(str,compiler)),'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler','-no-stdlib','-no-reflect','-classpath',os.pathsep.join(map(str,stdlib)),'-d',str(folder/'classes'),str(kotlin),str(probe)],check=True,capture_output=True)
   subprocess.run(['java','-cp',os.pathsep.join(map(str,[folder/'classes',*stdlib])),'com.paths.mobile.location.ProbeKt'],check=True,capture_output=True)
   main=folder/'main.swift';main.write_text('import Foundation\n'+'\n'.join(f'precondition(UploadEndpointPolicy.valid("{url}",debug:{str(debug).lower()}) == {str(expected).lower()})' for url,debug,expected in cases))
   subprocess.run(['swiftc',str(swift),str(main),'-o',str(folder/'probe')],check=True,capture_output=True)
   subprocess.run([str(folder/'probe')],check=True,capture_output=True)

 def test_accuracy_burst_is_bounded_and_never_runs_in_background(self):
  source=ROOT/'android/app/src/main/kotlin/com/paths/mobile/location/AccuracyBurst.kt'
  cache=Path.home()/'.gradle/caches/modules-2/files-2.1'
  compiler=[]
  for group,artifact,version in [('org.jetbrains.kotlin','kotlin-compiler-embeddable','2.4.0'),('org.jetbrains.kotlin','kotlin-stdlib','2.4.0'),('org.jetbrains.kotlin','kotlin-reflect','2.2.21'),('org.jetbrains.kotlin','kotlin-script-runtime','2.4.0'),('org.jetbrains.kotlinx','kotlinx-coroutines-core-jvm','1.10.2'),('org.jetbrains','annotations','13.0')]:compiler+=list((cache/group/artifact/version).glob('*/*.jar'))
  stdlib=list((cache/'org.jetbrains.kotlin/kotlin-stdlib/2.4.0').glob('*/*.jar'))
  with tempfile.TemporaryDirectory(prefix='paths-accuracy-') as temp:
   folder=Path(temp);probe=folder/'Probe.kt'
   probe.write_text('''package com.paths.mobile.location
fun main() {
 val burst=AccuracyBurst()
 check(!burst.active(1000,true,true))
 burst.start(1000)
 check(burst.active(1000,true,true))
 check(burst.active(20999,true,true))
 check(!burst.active(21000,true,true))
 check(!burst.active(2000,false,true))
 check(!burst.active(2000,true,false))
 burst.start(30000); burst.accept(80.0)
 check(burst.active(31000,true,true))
 burst.accept(Double.NaN); burst.accept(-1.0)
 check(burst.active(31000,true,true))
 burst.accept(25.0)
 check(!burst.active(31000,true,true))
 burst.start(50000); burst.stop()
 check(!burst.active(50001,true,true))
}
''')
   result=subprocess.run(['java','-cp',os.pathsep.join(map(str,compiler)),'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler','-no-stdlib','-no-reflect','-classpath',os.pathsep.join(map(str,stdlib)),'-d',str(folder/'classes'),str(source),str(probe)],capture_output=True,text=True)
   self.assertEqual(result.returncode,0,result.stderr)
   subprocess.run(['java','-cp',os.pathsep.join(map(str,[folder/'classes',*stdlib])),'com.paths.mobile.location.ProbeKt'],check=True,capture_output=True)
