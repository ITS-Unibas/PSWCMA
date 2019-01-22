using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.IO;
using System.Text.RegularExpressions;
using Newtonsoft.Json;
using System.Diagnostics;

namespace PSWCMA.Pre_Requisits
{
    static class GitInstaller
    {


        public static bool installGit()
        {
            const string gitPath = "C:\\Program Files\\Git\\bin\\git.exe";
            const string gitApi = "https://api.github.com/repos/git-for-windows/git/releases/latest";
            string downloadPath = Path.Combine(Environment.GetEnvironmentVariable("TEMP"), "git-stable.exe");

            if (!File.Exists(gitPath))
            {
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
                HttpClient client = new HttpClient();
                client.DefaultRequestHeaders.Add("User-Agent", "PSWCMA");
                HttpResponseMessage responseMessage = client.GetAsync(gitApi).Result;
                if (responseMessage.IsSuccessStatusCode)
                {
                    var dataObjects = responseMessage.Content.ReadAsStringAsync().Result;
                    Git git = JsonConvert.DeserializeObject<Git>(dataObjects);
                    string downloadUrl = "";
                    foreach (Asset asset in git.assets)
                    {
                        if (asset.name.Contains("64-bit.exe"))
                        {
                            downloadUrl = asset.browser_download_url;
                            break;

                        }
                    }
                    using (var webClient = new WebClient())
                    {
                        webClient.DownloadFile(downloadUrl, downloadPath);
                    }

                    if (File.Exists(downloadPath))
                    {
                        using (var process = Process.Start(downloadPath, "/silent"))
                        {
                            process.WaitForExit();
                        }

                        if (File.Exists(gitPath))
                        {
                            return true;
                        }

                        return false;
                    }

                }

                return false;

            }

            return true;

        }

        private class Git
        {
            public string url { get; set; }
            public string assets_url { get; set; }
            public string upload_url { get; set; }
            public string html_url { get; set; }
            public int id { get; set; }
            public string node_id { get; set; }
            public string tag_name { get; set; }
            public string target_commitish { get; set; }
            public string name { get; set; }
            public bool draft { get; set; }
            public JsonObjectAttribute author { get; set; }
            public bool prerelease { get; set; }
            public string created_at { get; set; }
            public string published_at { get; set; }
            public IList<Asset> assets { get; set; }
            public string tarball_url { get; set; }
            public string zipball_url { get; set; }
            public string body { get; set; }

        }

        private class Asset
        {
            public string url { get; set; }
            public int id { get; set; }
            public string node_id { get; set; }
            public string name { get; set; }
            public string label { get; set; }
            public JsonObjectAttribute uploader { get; set; }
            public string content_type { get; set; }
            public string state { get; set; }
            public int size { get; set; }
            public int downloaded_Count { get; set; }
            public string created_at { get; set; }
            public string published_at { get; set; }
            public string browser_download_url { get; set; }

        }

    }
}
