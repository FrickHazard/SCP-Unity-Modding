using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;

namespace FrickHazardModding
{
    public class AssetLoader : MonoBehaviour
    {
        public static AssetLoader Instance;
        public static string DataPath;

        private void Awake()
        {
            Debug.Log("AssetLoader loading");
            if (AssetLoader.Instance == null)
            {
                Debug.Log("Singleton for AssetLoader is null, assigning to this AssetLoader.");
                AssetLoader.Instance = this;
                UnityEngine.Object.DontDestroyOnLoad(this);
                return;
            }
            Debug.Log("AssetLoader ALready Exists");
            UnityEngine.Object.DestroyImmediate(base.gameObject);
        }

        // Use this for initialization
        public AssetBundle LoadAssetBundle(string assetBundleName)
        {
            var LoadedAssetBundle = AssetBundle.LoadFromFile(DataPath + "/" + assetBundleName);
            if (LoadedAssetBundle == null)
            {
                Debug.Log("Failed to load AssetBundle!");
                return null;
            }
            LoadedAssetBundle.Unload(false);
            return LoadedAssetBundle;
        }


        public List<string> AllAssetNamesInBundle(string assetBundleName)
        {
            List<string> result = new List<string>();
            var myLoadedAssetBundle = AssetBundle.LoadFromFile(DataPath + "/" + assetBundleName);
            if (myLoadedAssetBundle == null)
            {
                Debug.Log("Failed to load AssetBundle!");
                return null;
            };
            return myLoadedAssetBundle.GetAllAssetNames().ToList();
        }
    }
}