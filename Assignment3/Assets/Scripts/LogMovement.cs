using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LogMovement : MonoBehaviour
{
    public int speed;
    public int cutoff;
    public Vector3 spawn;
    public bool backwards = false;

    void Update()
    {
        transform.position += new Vector3(speed*Time.deltaTime, 0, 0);
        if (backwards)
        {
            if (transform.position.x >= cutoff)
            {
                transform.position = spawn;
            }
        }
        else
        {
            if (transform.position.x <= cutoff)
            {
                transform.position = spawn;
            }
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        other.gameObject.transform.parent = gameObject.transform;
    }

    private void OnTriggerExit(Collider other)
    {
        other.gameObject.transform.parent = null;
    }
}
