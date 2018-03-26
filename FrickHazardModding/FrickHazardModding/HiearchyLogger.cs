using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using System.IO;

namespace FrickHazardModding
{
    static class HiearchyLogger
    {

        public static void DumpScene(string fileName)
        {
            List<GameObject> allObjects = UnityEngine.Object.FindObjectsOfType<GameObject>().Where(go => go.activeInHierarchy).ToList();


            Debug.Log("Dumping scene");
            using (StreamWriter writer = new StreamWriter(fileName +".txt", false))
            {
                foreach (GameObject objectEntry in allObjects)
                {
                    DumpGameObject(objectEntry, writer, "");
                }
            }
            Debug.Log("Scene dumped");
        }

        private static void DumpGameObject(GameObject gameObject, StreamWriter writer, string indent)
        {
            writer.WriteLine("{0}+{1} {2}", indent, gameObject.name, gameObject.layer.ToString());

            foreach (Component component in gameObject.GetComponents<Component>())
            {
                DumpComponent(component, writer, indent + "  ");
            }

            foreach (Transform child in gameObject.transform)
            {
                DumpGameObject(child.gameObject, writer, indent + "  ");
            }
        }

        private static void DumpComponent(Component component, StreamWriter writer, string indent)
        {
            writer.WriteLine("{0}{1}", indent, (component == null ? "(null)" : component.GetType().Name));
        }
    }
}
