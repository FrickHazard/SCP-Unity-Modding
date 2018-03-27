using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace FrickHazardModding
{
    public static class ModMain
    {
        private static bool started = false;
        private static bool spawnedScp099Instance = false;
	    private static bool startedScp099Mod = false;

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

	    public static void InitiliazeSCP099Mod(Camera playerCamera)
	    {
		    if (startedScp099Mod == true) return;
            AssetBundle scp099ModEyeAssets = AssetLoader.Instance.LoadAssetBundle("scp099eyeprefab");
            var effect = playerCamera.gameObject.AddComponent<SCP099Effect>();
		    effect.EyePrefab = GameObject.Instantiate(scp099ModEyeAssets.LoadAsset<GameObject>("Assets/scp099eyeprefab.prefab")); ;
			// 11 and 12 seem to be used for walls and floor
		    effect.RayCastMask = (1 << 11) | (1 << 12);
		    startedScp099Mod = true;

	    }

	    public static void SpawnSCP099TV(Vector3 position, Camera playerCamera)
	    {
            if(spawnedScp099Instance == true) return;
		    AssetBundle scp099ModWeaponizedScp099Assets = AssetLoader.Instance.LoadAssetBundle("tv");
			GameObject scp099TvPrefab = scp099ModWeaponizedScp099Assets.LoadAsset<GameObject>("Assets/tv.prefab");
		    GameObject scp099TvGameObject = GameObject.Instantiate(scp099TvPrefab) as GameObject;
		    SCP099Canvas canvas = scp099TvGameObject.AddComponent<SCP099Canvas>();
		    canvas.playerTransform = playerCamera.transform;
			scp099TvGameObject.transform.position = position;
		    canvas.Effect = playerCamera.GetComponent<SCP099Effect>();
	        scp099ModWeaponizedScp099Assets.Unload(false);
	        spawnedScp099Instance = true;
        }
    }
}
