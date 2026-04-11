package com.example.hungzo_app

import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.IsoDep
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "iso7816_nfc"
    private var nfcAdapter: NfcAdapter? = null

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        nfcAdapter = NfcAdapter.getDefaultAdapter(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "startReader") {
                    enableReader()
                    result.success(null)
                }
            }
    }

    /* ================= Enable Reader ================= */

    private fun enableReader() {
        nfcAdapter?.enableReaderMode(
            this,
            { tag -> readIsoDep(tag) },
            NfcAdapter.FLAG_READER_NFC_A or
                    NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK,
            null
        )
    }

    /* ================= ISO7816 READ ================= */

    private fun readIsoDep(tag: Tag) {

        Thread {
            try {
                val isoDep = IsoDep.get(tag)
                isoDep.connect()

                // Example APDU SELECT command
                val command = byteArrayOf(
                    0x00, 0xA4.toByte(), 0x04, 0x00, 0x02, 0x3F, 0x00
                )

                val response = isoDep.transceive(command)

                val hex = response.joinToString(" ") {
                    String.format("%02X", it)
                }

                isoDep.close()

                /* ⭐ FIX → RETURN ON MAIN THREAD */
                runOnUiThread {
                    MethodChannel(
                        flutterEngine!!.dartExecutor.binaryMessenger,
                        CHANNEL
                    ).invokeMethod("readIso7816", hex)
                }

            } catch (e: Exception) {
                e.printStackTrace()
            }
        }.start()
    }
}
