// Offline synthetic-print smoke test. Not an iOS or student-handwriting benchmark.
import AppKit
import Vision
import Foundation
let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
let cases: [(String,[String])] = [
 ("printed", ["학생은 자신의 생각을 근거와 함께 설명한다.", "타인의 의견을 존중하며 서로 다른 관점을 비교한다."]),
 ("paragraphs", ["사회적 신뢰는 공동체의 협력을 가능하게 한다.", "서로 약속을 지킬 때 불필요한 비용을 줄일 수 있다.", "", "그러나 신뢰만으로 모든 문제를 해결할 수는 없다.", "공정한 제도와 책임 있는 행동이 함께 필요하다."]),
 ("mixed", ["2026년 학생 30명 중 15명은 A안을 선택했다.", "비율은 50%이며, B안의 값은 3.14이다.", "비교: A > B, x = 2, 증가율 +10%, 감소율 -5%."])
]
var records: [[String:Any]] = []
for (name, lines) in cases {
 let width = 1800, height = 900
 let rep = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:width,pixelsHigh:height,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 NSGraphicsContext.saveGraphicsState()
 NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep:rep)
 NSColor.white.setFill(); NSRect(x:0,y:0,width:width,height:height).fill()
 let font = NSFont(name:"AppleSDGothicNeo-Regular",size:46)!
 for (i,line) in lines.enumerated() {
  (line as NSString).draw(at:NSPoint(x:80,y:height-120-i*95),withAttributes:[.font:font,.foregroundColor:NSColor.black])
 }
 NSGraphicsContext.restoreGraphicsState()
 try rep.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent(name+".png"))
 for trial in 0..<3 {
  let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate
  request.recognitionLanguages = ["ko-KR","en-US"]; request.usesLanguageCorrection = false
  let langs = try request.supportedRecognitionLanguages()
  guard langs.contains("ko-KR") else { fatalError("Korean unsupported") }
  let start=ProcessInfo.processInfo.systemUptime
  try VNImageRequestHandler(cgImage:rep.cgImage!,options:[:]).perform([request])
  let elapsed=ProcessInfo.processInfo.systemUptime-start
  let obs=request.results ?? []
  records.append(["case":name,"trial":trial,"reference":lines.joined(separator:"\n"),"text":obs.compactMap{$0.topCandidates(1).first?.string}.joined(separator:"\n"),"seconds":elapsed,"revision":request.revision,"boxes":obs.map{["x":$0.boundingBox.minX,"y":$0.boundingBox.minY,"width":$0.boundingBox.width,"height":$0.boundingBox.height]}])
 }
}
let output: [String:Any] = ["scope":"synthetic printed only; macOS; no Provider", "os":ProcessInfo.processInfo.operatingSystemVersionString,"font":"AppleSDGothicNeo-Regular 46px","image_size":[1800,900],"language_correction":false,"records":records]
try JSONSerialization.data(withJSONObject:output,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("raw.json"))
print("Offline Vision completed: 3 synthetic pages x 3 trials")
