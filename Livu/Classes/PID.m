#import "PID.h"

#include <time.h>

static double Kproportional;
static double Kintegral;
static double Kderivative;
static uint64_t processVariable;
static uint64_t manipulatedVariable;
static uint64_t setPoint;
static uint64_t lastTime;
static uint64_t lastError;
static uint64_t integralError;

uint64_t update()
{
    uint64_t currentTime = time(0);
    double deltaTime = (double)(currentTime - lastTime);
    
    double proportionalError = setPoint - processVariable;
    integralError += (proportionalError * deltaTime);
    double derivativeError = (proportionalError - lastError) / deltaTime;
    
    manipulatedVariable = Kproportional * proportionalError + Kintegral * integralError + Kderivative * derivativeError;
    
    lastError = proportionalError;
    lastTime = currentTime;
    
    return manipulatedVariable;
}

void setConstants(double p, double i, double d)
{
    Kproportional = p;
    Kintegral = i;
    Kderivative = d;
}