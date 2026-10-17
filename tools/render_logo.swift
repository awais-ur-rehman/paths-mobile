import AppKit
let input = CommandLine.arguments[1], output = CommandLine.arguments[2]
let image = NSImage(contentsOfFile: input)!
let size = NSSize(width: 816, height: 256)
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 816, pixelsHigh: 256, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
image.draw(in: NSRect(origin: .zero, size: size))
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
