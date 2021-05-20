using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    public CharacterController controller;
    public Transform cam3p;
    public Transform cam1p;
    public Vector3 spawn;
    public float speed = 250f;
    public float turnSmoothTime = 0.1f;
    public float sensitivity = 20f;
    public int maxLives = 99;
    public float gravity = -90;
    public float jump = 20;

    private float turnSmoothVelocity;
    private int lives;
    private bool cam = false; // true if 1st person
    private float xRotation = 0f;
    private Vector3 velocity;

    private void Start()
    {
        lives = maxLives;
        Cursor.lockState = CursorLockMode.Locked;
    }

    // Update is called once per frame
    void Update()
    {
        // Movement Input
        float horizontal = Input.GetAxisRaw("Horizontal");
        float vertical = Input.GetAxisRaw("Vertical");
        // Camera Toggle
        if (Input.GetKeyDown("c"))
        {
            cam3p.gameObject.SetActive(cam);
            cam1p.gameObject.SetActive(!cam);
            cam = !cam;
        }
        // 1st Person Camera
        if (cam)
        {
            float mouseX = Input.GetAxis("Mouse X") * sensitivity * Time.deltaTime;
            float mouseY = Input.GetAxis("Mouse Y") * sensitivity * Time.deltaTime;

            xRotation -= mouseY;
            xRotation = Mathf.Clamp(xRotation, -90f, 90f);
            cam1p.transform.localRotation = Quaternion.Euler(xRotation, 0f, 0f);
            transform.Rotate(Vector3.up * mouseX);

            Vector3 direction = transform.right * horizontal + transform.forward * vertical;
            controller.Move(direction * speed * Time.deltaTime);
        }
        // 3rd Person Camera
        else
        {
            Vector3 direction = new Vector3(horizontal, 0f, vertical).normalized;

            if (direction.magnitude >= 1.0f)
            {
                float targetAngle = Mathf.Atan2(direction.x, direction.z) * Mathf.Rad2Deg + cam3p.eulerAngles.y;
                float angle = Mathf.SmoothDampAngle(transform.eulerAngles.y, targetAngle, ref turnSmoothVelocity, turnSmoothTime);
                transform.rotation = Quaternion.Euler(0f, angle, 0f);

                Vector3 moveDirection = Quaternion.Euler(0f, targetAngle, 0f) * Vector3.forward;
                controller.Move(moveDirection.normalized * speed * Time.deltaTime);
            }
        }
        // Ground Check
        if (controller.isGrounded && velocity.y < 0)
        {
            velocity.y = -2f;
        }
        // Jump
        if (Input.GetButtonDown("Jump") && controller.isGrounded)
        {
            velocity.y = Mathf.Sqrt(jump * -2f * gravity);
        }
        velocity.y += gravity * Time.deltaTime;

        controller.Move(velocity * Time.deltaTime);
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
            // CALL GAME OVER SCENE
        }
        else
        {
            gameObject.SetActive(false);
            transform.position = spawn;
            gameObject.SetActive(true);
        }
    }
}
