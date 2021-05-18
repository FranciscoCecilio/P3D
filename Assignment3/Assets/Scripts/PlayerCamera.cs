using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerCamera : MonoBehaviour
{
    public CharacterController controller;
    public Transform cam;
    public float speed = 250f;
    public float turnSmoothTime = 0.1f;
    public Vector3 spawn;
    public int maxLives = 99;
    public float gravity = 90;
    public float jump = 20;

    private float turnSmoothVelocity;
    private int lives;

    private void Start()
    {
        lives = maxLives;
    }

    // Update is called once per frame
    void Update()
    {
        GetComponent<Rigidbody>().AddForce(Vector3.down * gravity * Time.deltaTime);

        float horizontal = Input.GetAxisRaw("Horizontal");
        float vertical = Input.GetAxisRaw("Vertical");
        Vector3 direction = new Vector3(horizontal, 0f, vertical).normalized;

        if (direction.magnitude >= 1.0f)
        {
            float targetAngle = Mathf.Atan2(direction.x, direction.z) * Mathf.Rad2Deg + cam.eulerAngles.y;
            float angle = Mathf.SmoothDampAngle(transform.eulerAngles.y, targetAngle, ref turnSmoothVelocity, turnSmoothTime);
            transform.rotation = Quaternion.Euler(0f, angle, 0f);

            Vector3 moveDirection = Quaternion.Euler(0f, targetAngle, 0f) * Vector3.forward;
            controller.Move(moveDirection.normalized * speed * Time.deltaTime);
        }
        /**
         * TO-DO
        if (Input.GetButtonDown("Jump") && controller.isGrounded)
            controller.Move(0f, Mathf.Sqrt(jump * gravity)) * Time.deltaTime, 0f);
        */
    }

    private void OnCollisionEnter(Collision collision)
    {
 
    }

    public void TakeLife()
    {
        lives--;
        if (lives < 0)
        {
            Destroy(gameObject);
            // CALL SCENE
        }
        else
        {
            Debug.Log("ded");
            gameObject.SetActive(false);
            transform.position = spawn;
            gameObject.SetActive(true);
        }
    }
}
