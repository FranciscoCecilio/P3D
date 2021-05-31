using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class TimeManager : MonoBehaviour
{
    public GameObject lightSource;
    public GameObject postProcessing;
    public Material daysky;
    public Material nightsky;

    private Volume pp;
    private Bloom bloom;
    private WhiteBalance whiteBalance;
    private int time = 1;

    // Start is called before the first frame update
    void Start()
    {
        pp = postProcessing.GetComponent<Volume>();
        pp.profile.TryGet(out bloom);
        pp.profile.TryGet(out whiteBalance);
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.T))
        {
            switch (time)
            {
                case 0:
                    Morning();
                    time++;
                    break;
                case 1:
                    Afternoon();
                    time++;
                    break;
                case 2:
                    Night();
                    time++;
                    break;
            }
            if (time > 2)
            {
                time = 0;
            }
        }
    }

    public void Morning()
    {
        RenderSettings.skybox = daysky;
        RenderSettings.fog = false;

        lightSource.GetComponent<Light>().color = new Color(1, 0.9568627f, 0.8431373f, 1);
        lightSource.GetComponent<Light>().transform.eulerAngles = new Vector3(120, -90, 0);
        lightSource.GetComponent<Light>().intensity = 3;

        bloom.intensity.overrideState = true;
        bloom.intensity.value = 3;
        bloom.tint.value = new Color(0.8431373f, 0.9372549f, 1);
        bloom.dirtIntensity.value = 3;
        whiteBalance.temperature.value = -10;
    }

    public void Afternoon()
    {
        RenderSettings.skybox = daysky;
        RenderSettings.fog = false;

        lightSource.GetComponent<Light>().color = new Color(1, 0.9568627f, 0.8431373f, 1);
        lightSource.GetComponent<Light>().transform.eulerAngles = new Vector3(30, -90, 0);
        lightSource.GetComponent<Light>().intensity = 3;

        bloom.intensity.overrideState = true;
        bloom.intensity.value = 2;
        bloom.tint.value = new Color(0.7075472f, 0.4539622f, 0);
        bloom.dirtIntensity.value = 2;
        whiteBalance.temperature.value = 10;
    }

    public void Night()
    {
        RenderSettings.skybox = nightsky;
        RenderSettings.fog = true;
        RenderSettings.fogMode = FogMode.ExponentialSquared;
        RenderSettings.fogDensity = 0.02f;

        lightSource.GetComponent<Light>().color = new Color(0.2156863f, 0.2156863f, 0.2156863f, 1);
        lightSource.GetComponent<Light>().transform.eulerAngles = new Vector3(45, 45, 0);
        lightSource.GetComponent<Light>().intensity = 1;

        bloom.intensity.overrideState = true;
        bloom.intensity.value = 0;
        bloom.tint.overrideState = true;
        bloom.tint.value = new Color(0.3019608f, 0.3019608f, 0.3019608f);
        bloom.dirtIntensity.value = 0;
        whiteBalance.temperature.value = 0;
    }
}
