using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CarMovement : MonoBehaviour
{
    public int Speed; // Positive = North

    private bool inside = false;

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        transform.position += new Vector3(Speed*Time.deltaTime, 0, 0);
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("CarDestroyer"))
        {
            Destroy(gameObject);
        }
        else if (other.CompareTag("Player") && !inside)
        {
            inside = true;
            other.gameObject.GetComponent<PlayerCamera>().TakeLife();
        }
    }

    private void OnTriggerExit(Collider other)
    {
        inside = false;
    }
}
