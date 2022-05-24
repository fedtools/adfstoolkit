/*
 * Derived from https://github.com/google/google-authenticator-android/blob/master/AuthenticatorApp/src/main/java/com/google/android/apps/authenticator/Base32String.java
 * 
 * Copyright (C) 2016 BravoTango86
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
namespace Urn.Adfstk.Application.Helpers
{
    public static class Base32
    {

        private static readonly char[] DIGITS;
        private static readonly int MASK;
        private static readonly int SHIFT;
        private static Dictionary<char, int> CHAR_MAP = new Dictionary<char, int>();
        private const string SEPARATOR = "-";

        static Base32()
        {
            DIGITS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".ToCharArray();
            MASK = DIGITS.Length - 1;
            SHIFT = numberOfTrailingZeros(DIGITS.Length);
            for (int i = 0; i < DIGITS.Length; i++) CHAR_MAP[DIGITS[i]] = i;
        }

        private static int numberOfTrailingZeros(int i)
        {
            // HD, Figure 5-14
            int y;
            if (i == 0) return 32;
            int n = 31;
            y = i << 16; if (y != 0) { n = n - 16; i = y; }
            y = i << 8; if (y != 0) { n = n - 8; i = y; }
            y = i << 4; if (y != 0) { n = n - 4; i = y; }
            y = i << 2; if (y != 0) { n = n - 2; i = y; }
            return n - (int)((uint)(i << 1) >> 31);
        }

        public static byte[] FromBase32String(string encoded)
        {
            // Remove whitespace and separators
            encoded = encoded.Trim().Replace(SEPARATOR, "");

            // Remove padding. Note: the padding is used as hint to determine how many
            // bits to decode from the last incomplete chunk (which is commented out
            // below, so this may have been wrong to start with).
            encoded = Regex.Replace(encoded, "[=]*$", "");

            // Canonicalize to all upper case
            encoded = encoded.ToUpper();
            if (encoded.Length == 0)
            {
                return new byte[0];
            }
            int encodedLength = encoded.Length;
            int outLength = encodedLength * SHIFT / 8;
            byte[] result = new byte[outLength];
            int buffer = 0;
            int next = 0;
            int bitsLeft = 0;
            foreach (char c in encoded.ToCharArray())
            {
                if (!CHAR_MAP.ContainsKey(c))
                {
                    throw new DecodingException("Illegal character: " + c);
                }
                buffer <<= SHIFT;
                buffer |= CHAR_MAP[c] & MASK;
                bitsLeft += SHIFT;
                if (bitsLeft >= 8)
                {
                    result[next++] = (byte)(buffer >> (bitsLeft - 8));
                    bitsLeft -= 8;
                }
            }
            // We'll ignore leftover bits for now.
            //
            if (next != outLength || bitsLeft >= SHIFT)
            {
                throw new DecodingException("Bits left: " + bitsLeft);
            }
            return result;
        }


        public static string ToBase32String(byte[] data, bool padOutput = false)
        {
            if (data.Length == 0)
            {
                return "";
            }
            //Todo
            //Pad input to length

            // SHIFT is the number of bits per output character, so the length of the
            // output is the length of the input multiplied by 8/SHIFT, rounded up.
            if (data.Length >= (1 << 28))
            {
                // The computation below will fail, so don't do it.
                throw new ArgumentOutOfRangeException("data");
            }

            int outputLength = (data.Length * 8 + SHIFT - 1) / SHIFT;
            StringBuilder result = new StringBuilder(outputLength);

            int buffer = data[0];
            int next = 1;
            int bitsLeft = 8;
            while (bitsLeft > 0 || next < data.Length)
            {
                if (bitsLeft < SHIFT)
                {
                    if (next < data.Length)
                    {
                        buffer <<= 8;
                        buffer |= (data[next++] & 0xff);
                        bitsLeft += 8;
                    }
                    else
                    {
                        int pad = SHIFT - bitsLeft;
                        buffer <<= pad;
                        bitsLeft += pad;
                    }
                }
                int index = MASK & (buffer >> (bitsLeft - SHIFT));
                bitsLeft -= SHIFT;
                result.Append(DIGITS[index]);
            }
            if (padOutput)
            {
                int padding = 8 - (result.Length % 8);
                if (padding > 0) result.Append(new string('=', padding == 8 ? 0 : padding));
            }
            return result.ToString();
        }

        private class DecodingException : Exception
        {
            public DecodingException(string message) : base(message)
            {
            }
        }
    }
}
//using System;
//using System.Collections.Generic;
//using System.Text;

//namespace Urn.Adfstk.Application.Helpers
//{
//    /// <summary>
//    /// Class used for conversion between byte array and Base32 notation
//    /// http://scottless.com/blog/archive/2014/02/15/base32-encoder-and-decoder-in-c.aspx
//    /// </summary>
//    public class Base32
//    {
//        /// <summary>
//        /// Size of the regular byte in bits
//        /// </summary>
//        private const int InByteSize = 8;

//        /// <summary>
//        /// Size of converted byte in bits
//        /// </summary>
//        private const int OutByteSize = 5;

//        /// <summary>
//        /// Alphabet
//        /// </summary>
//        private const string Base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

//        /// <summary>
//        /// Convert byte array to Base32 format
//        /// </summary>
//        /// <param name="bytes">An array of bytes to convert to Base32 format</param>
//        /// <returns>Returns a string representing byte array</returns>
//        public static string ToBase32String(byte[] bytes)
//        {
//            // Check if byte array is null
//            if (bytes == null)
//            {
//                return null;
//            }
//            // Check if empty
//            else if (bytes.Length == 0)
//            {
//                return string.Empty;
//            }

//            // Prepare container for the final value
//            StringBuilder builder = new StringBuilder(bytes.Length * InByteSize / OutByteSize);

//            // Position in the input buffer
//            int bytesPosition = 0;

//            // Offset inside a single byte that <bytesPosition> points to (from left to right)
//            // 0 - highest bit, 7 - lowest bit
//            int bytesSubPosition = 0;

//            // Byte to look up in the dictionary
//            byte outputBase32Byte = 0;

//            // The number of bits filled in the current output byte
//            int outputBase32BytePosition = 0;

//            // Iterate through input buffer until we reach past the end of it
//            while (bytesPosition < bytes.Length)
//            {
//                // Calculate the number of bits we can extract out of current input byte to fill missing bits in the output byte
//                int bitsAvailableInByte = Math.Min(InByteSize - bytesSubPosition, OutByteSize - outputBase32BytePosition);

//                // Make space in the output byte
//                outputBase32Byte <<= bitsAvailableInByte;

//                // Extract the part of the input byte and move it to the output byte
//                outputBase32Byte |= (byte)(bytes[bytesPosition] >> (InByteSize - (bytesSubPosition + bitsAvailableInByte)));

//                // Update current sub-byte position
//                bytesSubPosition += bitsAvailableInByte;

//                // Check overflow
//                if (bytesSubPosition >= InByteSize)
//                {
//                    // Move to the next byte
//                    bytesPosition++;
//                    bytesSubPosition = 0;
//                }

//                // Update current base32 byte completion
//                outputBase32BytePosition += bitsAvailableInByte;

//                // Check overflow or end of input array
//                if (outputBase32BytePosition >= OutByteSize)
//                {
//                    // Drop the overflow bits
//                    outputBase32Byte &= 0x1F;  // 0x1F = 00011111 in binary

//                    // Add current Base32 byte and convert it to character
//                    builder.Append(Base32Alphabet[outputBase32Byte]);

//                    // Move to the next byte
//                    outputBase32BytePosition = 0;
//                }
//            }

//            // Check if we have a remainder
//            if (outputBase32BytePosition > 0)
//            {
//                // Move to the right bits
//                outputBase32Byte <<= (OutByteSize - outputBase32BytePosition);

//                // Drop the overflow bits
//                outputBase32Byte &= 0x1F;  // 0x1F = 00011111 in binary

//                // Add current Base32 byte and convert it to character
//                builder.Append(Base32Alphabet[outputBase32Byte]);
//            }

//            return builder.ToString();
//        }

//        /// <summary>
//        /// Convert base32 string to array of bytes
//        /// </summary>
//        /// <param name="base32String">Base32 string to convert</param>
//        /// <returns>Returns a byte array converted from the string</returns>
//        public static byte[] FromBase32String(string base32String)
//        {
//            // Check if string is null
//            if (base32String == null)
//            {
//                return null;
//            }
//            // Check if empty
//            else if (base32String == string.Empty)
//            {
//                return new byte[0];
//            }

//            // Convert to upper-case
//            string base32StringUpperCase = base32String.ToUpperInvariant();

//            // Prepare output byte array
//            byte[] outputBytes = new byte[base32StringUpperCase.Length * OutByteSize / InByteSize];

//            // Check the size
//            if (outputBytes.Length == 0)
//            {
//                throw new ArgumentException("Specified string is not valid Base32 format because it doesn't have enough data to construct a complete byte array");
//            }

//            // Position in the string
//            int base32Position = 0;

//            // Offset inside the character in the string
//            int base32SubPosition = 0;

//            // Position within outputBytes array
//            int outputBytePosition = 0;

//            // The number of bits filled in the current output byte
//            int outputByteSubPosition = 0;

//            // Normally we would iterate on the input array but in this case we actually iterate on the output array
//            // We do it because output array doesn't have overflow bits, while input does and it will cause output array overflow if we don't stop in time
//            while (outputBytePosition < outputBytes.Length)
//            {
//                // Look up current character in the dictionary to convert it to byte
//                int currentBase32Byte = Base32Alphabet.IndexOf(base32StringUpperCase[base32Position]);

//                // Check if found
//                if (currentBase32Byte < 0)
//                {
//                    throw new ArgumentException(string.Format("Specified string is not valid Base32 format because character \"{0}\" does not exist in Base32 alphabet", base32String[base32Position]));
//                }

//                // Calculate the number of bits we can extract out of current input character to fill missing bits in the output byte
//                int bitsAvailableInByte = Math.Min(OutByteSize - base32SubPosition, InByteSize - outputByteSubPosition);

//                // Make space in the output byte
//                outputBytes[outputBytePosition] <<= bitsAvailableInByte;

//                // Extract the part of the input character and move it to the output byte
//                outputBytes[outputBytePosition] |= (byte)(currentBase32Byte >> (OutByteSize - (base32SubPosition + bitsAvailableInByte)));

//                // Update current sub-byte position
//                outputByteSubPosition += bitsAvailableInByte;

//                // Check overflow
//                if (outputByteSubPosition >= InByteSize)
//                {
//                    // Move to the next byte
//                    outputBytePosition++;
//                    outputByteSubPosition = 0;
//                }

//                // Update current base32 byte completion
//                base32SubPosition += bitsAvailableInByte;

//                // Check overflow or end of input array
//                if (base32SubPosition >= OutByteSize)
//                {
//                    // Move to the next character
//                    base32Position++;
//                    base32SubPosition = 0;
//                }
//            }

//            return outputBytes;
//        }
//    }
//}
