using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LogSpawner : MonoBehaviour
{
    public GameObject log;
    public float cooldown;
    public int speed;

    private float timeLeft = 0;

    void Update()
    {
        if (timeLeft <= 0)
        {
            GameObject.Instantiate(log, transform).GetComponent<LogMovement>().speed = speed;
            timeLeft = cooldown;
        }
        timeLeft -= Time.deltaTime;
    }
}
