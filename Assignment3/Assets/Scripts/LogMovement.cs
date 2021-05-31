using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LogMovement : MonoBehaviour
{
    public int speed;
    // public bool backwards = false;
    // public int cutoff;
    // public Vector3 spawn;

    private int dir = -1;

    void Update()
    {
        transform.position += new Vector3(speed*Time.deltaTime, /*dir*0.5f*Time.deltaTime*/0, 0);
        if (transform.position.y < 18.5 || transform.position.y > 19)
        {
            dir *= -1;
        }

        /** /
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
        /**/
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("LogDestroyer"))
        {
            Destroy(gameObject);
        }
        else
        {
            other.gameObject.transform.parent = gameObject.transform;
        }
    }

    private void OnTriggerExit(Collider other)
    {
        other.gameObject.transform.parent = null;
    }
}
