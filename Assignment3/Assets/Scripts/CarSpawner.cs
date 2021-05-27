using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public struct Vehicle
{
    public GameObject Car;
    public float cooldown;
}

public class CarSpawner : MonoBehaviour
{
    public List<Vehicle> cars;
    public int Speed;

    private float timeLeft = 0;

    void Update()
    {
        if (timeLeft <= 0)
        {
            int a = Random.Range(0, cars.Count);
            GameObject.Instantiate(cars[a].Car, transform).GetComponent<CarMovement>().Speed = Speed;
            timeLeft = cars[a].cooldown;
        }
        timeLeft -= Time.deltaTime;
    }
}
