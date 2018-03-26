using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace FrickHazardModding
{
    public static class SCP173SkinChanger
    {

        public static void ChangeModel(GameObject scp173, GameObject newModel)
        {
            if (scp173.transform.Find("Model") != null) {
                GameObject oldModelObject = scp173.transform.Find("Model").transform.Find("U3DMesh").gameObject;
                UnityEngine.Object.Destroy(oldModelObject);
                newModel.transform.parent = scp173.transform.Find("Model").transform;
            }

            else throw new Exception("This is just a demo feature scp173 model already replaced");
        }
    }
}
