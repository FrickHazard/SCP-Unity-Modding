using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace FrickHazardModding
{
    public static class ModMain
    {
        private static bool started = false;

        public static void Start(string dataPath)
        {
            if (started) throw (new Exception("Mod Has Already Started"));

            started = true;

            GameObject modSystem = new GameObject();

            modSystem.AddComponent<AssetLoader>();

            AssetLoader.DataPath = dataPath;
        }

        // used for debugging
        public static void LogScene(string fileName)
        {
            HiearchyLogger.DumpScene(fileName);
        }

        public static void ChangeSCP173Model(GameObject scp173)
        {
            AssetBundle modAssets = AssetLoader.Instance.LoadAssetBundle("bird");
            GameObject bigBirdPrefab = modAssets.LoadAsset<GameObject>("Assets/BIRD.prefab");
            GameObject bigBirdModelGameObject = GameObject.Instantiate(bigBirdPrefab);
            SCP173SkinChanger.ChangeModel(scp173, bigBirdModelGameObject);
        }

	    public static void InitiliazeSCP099(GameObject scp173, Camera playerCamera)
	    {
		    LogScene("sceneDump");
	        AssetBundle scp099ModAssets = AssetLoader.Instance.LoadAssetBundle("scp099eyeprefab");
            GameObject scp099EyePrefab = scp099ModAssets.LoadAsset<GameObject>("Assets/scp099eyeprefab.prefab");

            if (scp173.transform.Find("Model") != null)
		    {
			    GameObject oldModelObject = scp173.transform.Find("Model").transform.Find("U3DMesh").gameObject;
			    SCP099Canvas canvas = oldModelObject.AddComponent<SCP099Canvas>();
				canvas.playerTransform = playerCamera.transform;
			    canvas.Effect = playerCamera.gameObject.AddComponent<SCP099Effect>();
			    canvas.Effect.EyePrefab = scp099EyePrefab;
				// 11 and 12 seem to be used for walls and floor
			    canvas.Effect.RayCastMask = (1 << 11) | (1 << 12);
		    }
	    }
    }
}
