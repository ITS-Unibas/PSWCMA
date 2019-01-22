using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using Newtonsoft.Json;
using System.Security.Cryptography;

namespace PSWCMA.ModuleClasses
{
    static class FileHashOperations
    {
        public static bool filehasChanged(string filepath, string config)
        {
            string jsonPath = Path.Combine(filepath, "FileHashes.json");
            if(File.Exists(jsonPath))
            {
                string json = File.ReadAllText(jsonPath);
                IList<HashObject> hashObjects = JsonConvert.DeserializeObject<List<HashObject>>(json);
                //string configPath = Path.Combine(config, new DirectoryInfo(config).Name + ".ps1");

                HashObject hashObject = hashObjects.Where(item => item.File.Equals(config)).First();

                return calculateHash(config) != hashObject.Hash;
            }

            return true;
        }

        public static void updateFileHashes(string filepath, IList<string> configFiles)
        {
            string jsonPath = Path.Combine(filepath, "FileHashes.json");
            IList<HashObject> hashObjects = new List<HashObject>();
            foreach(string config in configFiles)
            {
                string configPath = Path.Combine(config, new DirectoryInfo(config).Name + ".ps1");
                hashObjects.Add(new HashObject(configPath, calculateHash(configPath)));

            }

            string json = JsonConvert.SerializeObject(hashObjects, Formatting.Indented);
            File.WriteAllText(jsonPath, json);
        }

        private static string calculateHash(string filename)
        {
            using (var md5 = MD5.Create())
            {
                using (var stream = File.OpenRead(filename))
                {
                    return BitConverter.ToString(md5.ComputeHash(stream)).Replace("-", "").ToLowerInvariant();
                } 
            }
        }

        private class HashObject
        {
            public string File { get; }
            public string Hash { get; }

            public HashObject(string file, string hash)
            {
                File = file;
                Hash = hash;
            }
        }
    }
}
