using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public struct Vehicle
{
    public GameObject Car;
    public float Cooldown;
}

public class CarSpawner : MonoBehaviour
{
    public List<Vehicle> cars;
    public float Cooldown;
    public int Speed;
    private float timeLeft = 0;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (timeLeft <= 0)
        {
            int a = Random.Range(0, cars.Count);
            GameObject.Instantiate(cars[a].Car, transform).GetComponent<CarMovement>().Speed = Speed;
            timeLeft = cars[a].Cooldown;
        }
        timeLeft -= Time.deltaTime;
    }
}
