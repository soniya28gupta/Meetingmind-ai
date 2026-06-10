import 'dart:io';

class AudioHelper {
  /// Generates a 44-byte WAV header for mono PCM 16-bit audio
  static List<int> getWavHeader(int numBytes, int sampleRate) {
    final header = List<int>.filled(44, 0);
    final byteRate = sampleRate * 2; // 16-bit mono = 2 bytes per sample

    // RIFF Chunk Descriptor
    header[0] = 0x52; // 'R'
    header[1] = 0x49; // 'I'
    header[2] = 0x46; // 'F'
    header[3] = 0x46; // 'F'
    
    final fileSize = numBytes + 36;
    header[4] = fileSize & 0xff;
    header[5] = (fileSize >> 8) & 0xff;
    header[6] = (fileSize >> 16) & 0xff;
    header[7] = (fileSize >> 24) & 0xff;

    header[8] = 0x57;  // 'W'
    header[9] = 0x41;  // 'A'
    header[10] = 0x56; // 'V'
    header[11] = 0x45; // 'E'

    // fmt Sub-chunk
    header[12] = 0x66; // 'f'
    header[13] = 0x6d; // 'm'
    header[14] = 0x74; // 't'
    header[15] = 0x20; // ' '

    header[16] = 16; // Subchunk1Size (16 for PCM)
    header[17] = 0;
    header[18] = 0;
    header[19] = 0;

    header[20] = 1; // AudioFormat (1 for PCM)
    header[21] = 0;

    header[22] = 1; // NumChannels (1 for mono)
    header[23] = 0;

    header[24] = sampleRate & 0xff;
    header[25] = (sampleRate >> 8) & 0xff;
    header[26] = (sampleRate >> 16) & 0xff;
    header[27] = (sampleRate >> 24) & 0xff;

    header[28] = byteRate & 0xff;
    header[29] = (byteRate >> 8) & 0xff;
    header[30] = (byteRate >> 16) & 0xff;
    header[31] = (byteRate >> 24) & 0xff;

    header[32] = 2; // BlockAlign (Channels * BitsPerSample / 8)
    header[33] = 0;

    header[34] = 16; // BitsPerSample (16 bits)
    header[35] = 0;

    // data Sub-chunk
    header[36] = 0x64; // 'd'
    header[37] = 0x61; // 'a'
    header[38] = 0x74; // 't'
    header[39] = 0x61; // 'a'

    header[40] = numBytes & 0xff;
    header[41] = (numBytes >> 8) & 0xff;
    header[42] = (numBytes >> 16) & 0xff;
    header[43] = (numBytes >> 24) & 0xff;

    return header;
  }

  /// Converts a raw PCM file to a playable WAV file by prepending the header
  static Future<void> convertPcmToWav(String pcmPath, String wavPath, int sampleRate) async {
    final pcmFile = File(pcmPath);
    if (!await pcmFile.exists()) return;

    final pcmBytes = await pcmFile.readAsBytes();
    final header = getWavHeader(pcmBytes.length, sampleRate);

    final wavFile = File(wavPath);
    final ios = wavFile.openWrite();
    ios.add(header);
    ios.add(pcmBytes);
    await ios.close();

    // Clean up temporary raw PCM file
    await pcmFile.delete();
  }
}
