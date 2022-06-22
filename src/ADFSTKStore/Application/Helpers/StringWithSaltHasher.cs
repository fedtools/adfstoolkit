using ADFSTk.Domain.Model;
using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;


namespace ADFSTk.Helpers
{
    public class StringWithSaltHasher
    {
        public HashWithSaltResult HashWithSalt(string stringToHash, string salt, string hashAlgorithm = null)
        {
            var result = new HashWithSaltResult(salt);
            HashAlgorithm hash;

            // Make sure hashing algorithm name is specified.
            if (hashAlgorithm == null)
                hashAlgorithm = "";

            // Initialize appropriate hashing algorithm class.
            switch (hashAlgorithm.ToUpper())
            {
                case "SHA1":
                    hash = new SHA1Managed();
                    break;

                case "SHA256":
                    hash = new SHA256Managed();
                    break;

                case "SHA384":
                    hash = new SHA384Managed();
                    break;

                case "SHA512":
                    hash = new SHA512Managed();
                    break;
                case "MD5":
                    hash = new MD5CryptoServiceProvider();
                    break;
                default:
                    hash = new SHA256Managed();
                    break;
            }

            
            byte[] saltBytes = Encoding.UTF8.GetBytes(salt);
            byte[] plainTextBytes  = Encoding.UTF8.GetBytes(stringToHash);
            List<byte> stringWithSaltBytes = new List<byte>();
            stringWithSaltBytes.AddRange(plainTextBytes );
            stringWithSaltBytes.AddRange(saltBytes);
            
            // Allocate array, which will hold plain text and salt.
            byte[] plainTextWithSaltBytes =
                    new byte[plainTextBytes.Length + saltBytes.Length];

            // Copy plain text bytes into resulting array.
            for (int i = 0; i < plainTextBytes.Length; i++)
                plainTextWithSaltBytes[i] = plainTextBytes[i];

            // Append salt bytes to the resulting array.
            for (int i = 0; i < saltBytes.Length; i++)
                plainTextWithSaltBytes[plainTextBytes.Length + i] = saltBytes[i];

            // Compute hash value of our plain text with appended salt.
            byte[] hashBytes = hash.ComputeHash(plainTextWithSaltBytes);

            // Create array which will hold hash and original salt bytes.
            byte[] hashWithSaltBytes = new byte[hashBytes.Length +
                                                saltBytes.Length];

            // Copy hash bytes into resulting array.
            for (int i = 0; i < hashBytes.Length; i++)
                hashWithSaltBytes[i] = hashBytes[i];

            // Append salt bytes to the result.
            for (int i = 0; i < saltBytes.Length; i++)
                hashWithSaltBytes[hashBytes.Length + i] = saltBytes[i];

            // Convert result into a base64-encoded string.
            result.Digest = Convert.ToBase64String(hashWithSaltBytes);

            StringBuilder builder = new StringBuilder();
            for (int i = 0; i < hashBytes.Length; i++)
            {
                builder.Append(hashBytes[i].ToString("x2"));
            }
            result.DigestHex = builder.ToString();
            return result;
        }

    }
}
