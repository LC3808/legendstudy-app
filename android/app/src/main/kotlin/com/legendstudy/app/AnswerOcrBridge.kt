package com.legendstudy.app

import android.graphics.BitmapFactory
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** Local OCR only. No draft, evaluation, or account mutation. */
class AnswerOcrBridge(messenger: BinaryMessenger) {
    private var busy = false
    init {
        MethodChannel(messenger, "com.legendstudy.app/answer-ocr").setMethodCallHandler { call, reply ->
            if (call.method != "recognize") { reply.notImplemented(); return@setMethodCallHandler }
            if (busy) { reply.error("BUSY", "Recognition in progress", null); return@setMethodCallHandler }
            try {
                val bytes = call.argument<ByteArray>("bytes") ?: error("Missing image")
                require(bytes.isNotEmpty() && bytes.size <= 20971520)
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
                require(bounds.outWidth > 0 && bounds.outHeight > 0 && bounds.outWidth.toLong() * bounds.outHeight <= 20000000)
                val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: error("Invalid image")
                val recognizer = TextRecognition.getClient(KoreanTextRecognizerOptions.Builder().build())
                busy = true
                recognizer.process(InputImage.fromBitmap(bitmap, 0))
                    .addOnSuccessListener { text ->
                        val lines = text.textBlocks.flatMap { it.lines }.map { line ->
                            mapOf("text" to line.text,
                                "top" to (line.boundingBox?.top ?: 0).toDouble() / bitmap.height,
                                "height" to (line.boundingBox?.height() ?: 0).toDouble() / bitmap.height)
                        }
                        reply.success(mapOf("engine" to "mlkit-korean", "lines" to lines))
                    }.addOnFailureListener { reply.error("OCR_FAILED", "Unable to recognize image", null) }
                    .addOnCompleteListener { recognizer.close(); bitmap.recycle(); busy = false }
            } catch (_: Exception) { busy = false; reply.error("OCR_FAILED", "Unable to recognize image", null) }
        }
    }
}
