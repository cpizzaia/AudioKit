// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#import "AKShakerDSP.hpp"
#import <AudioKit/AKLinearParameterRamp.hpp>
#import <AudioKit/AKDSPBase.hpp>

#include "Shakers.h"

class AKShakerDSP : public AKDSPBase {
private:
    float internalTrigger = 0;
    UInt8 type = 0;
    float amplitude = 0.5;
    stk::Shakers *shaker;

public:
    AKShakerDSP() {}
    ~AKShakerDSP() = default;

    /// Uses the ParameterAddress as a key
    void setParameter(AUParameterAddress address, float value, bool immediate) override {
        switch (address) {
            case AKShakerParameterType:
                type = (UInt8)value;
                break;
            case AKShakerParameterAmplitude:
                amplitude = value;
                break;
        }
    }

    /// Uses the ParameterAddress as a key
    float getParameter(AUParameterAddress address) override {
        return 0;
    }

    void init(int channelCount, double sampleRate) override {
        AKDSPBase::init(channelCount, sampleRate);

        stk::Stk::setSampleRate(sampleRate);
        shaker = new stk::Shakers();
    }

    void trigger() override {
        internalTrigger = 1;
    }

    void handleMIDIEvent(AUMIDIEvent const& midiEvent) override {
        uint8_t veloc = midiEvent.data[2];
        type = (UInt8)midiEvent.data[1];
        amplitude = (AUValue)veloc / 127.0;
        trigger();
    }

    void triggerTypeAmplitude(AUValue triggerType, AUValue amplitude) {
        type = triggerType;
        amplitude = amplitude;
        trigger();
    }

    void deinit() override {
        AKDSPBase::deinit();
        delete shaker;
    }

    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override {

        for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
            int frameOffset = int(frameIndex + bufferOffset);

            for (int channel = 0; channel < channelCount; ++channel) {
                float *out = (float *)outputBufferList->mBuffers[channel].mData + frameOffset;

                if (isStarted) {
                    if (internalTrigger == 1) {
                        float frequency = pow(2.0, (type - 69.0) / 12.0) * 440.0;
                        shaker->noteOn(frequency, amplitude);
                    }
                    *out = shaker->tick();
                } else {
                    *out = 0.0;
                }
            }
        }
        if (internalTrigger == 1) {
            internalTrigger = 0;
        }
    }
};

AKDSPRef akShakerCreateDSP() {
    return new AKShakerDSP();
}

void triggerTypeShakerDSP(AKDSPRef dsp, AUValue type, AUValue amplitude) {
    ((AKShakerDSP*)dsp)->triggerTypeAmplitude(type, amplitude);
}
