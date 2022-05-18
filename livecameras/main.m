// livecameras
//  usage:
//      livecameras
//
//      prints integer number of video cameras currently in use
//      return codes:  
//            VD_ERR_NO_ERR = 0
//            VD_ERR_ALL_DEVICES_FAILED = 2
//
//  note:
//      logs CMIOObjectGetPropertyData errors, but this log message to be ignored 
//      as per Apple
//
//  main.m
//  
//
//  Created by Tom Houpt on 22/5/18.
//
// based on https://github.com/antonfisher/go-media-devices-state/blob/main/pkg/camera/camera_darwin.mm

#import <AVFoundation/AVFoundation.h>
#import <CoreMediaIO/CMIOHardware.h>
#import <Foundation/Foundation.h>

//------------------------------------------------------------------------

bool isIgnoredDeviceUID(NSString *uid);
OSStatus getVideoDevicesCount(int *count);
OSStatus getVideoDevices(int count, CMIODeviceID *devices);
OSStatus getVideoDeviceUID(CMIOObjectID device, NSString **uid);
void getVideoDeviceDescription(NSString *uid, NSString **description);
OSStatus getVideoDeviceIsUsed(CMIOObjectID device, int *isUsed);
OSStatus IsCameraOn(int *on);

//------------------------------------------------------------------------

int main(int argc, const char * argv[]) {
    OSStatus status;
    int numCamerasOn = 0;
    
    @autoreleasepool {
        // insert code here...
        status = IsCameraOn(&numCamerasOn);

        printf("%d\n",numCamerasOn);


    }
    return status;
}



// TODO how to use single `common/errno.mm` file for both packages?
const int VD_ERR_NO_ERR = 0;
const int VD_ERR_OUT_OF_MEMORY = 1;
const int VD_ERR_ALL_DEVICES_FAILED = 2;

bool isIgnoredDeviceUID(NSString *uid) {
  // OBS virtual device always returns "is used" even when OBS is not running
  if ([uid isEqual:@"obs-virtual-cam-device"]) {
    return true;
  }
  return false;
}

OSStatus getVideoDevicesCount(int *count) {
  OSStatus err;
  UInt32 dataSize = 0;

  CMIOObjectPropertyAddress prop = {kCMIOHardwarePropertyDevices,
                                    kCMIOObjectPropertyScopeGlobal,
                                    kCMIOObjectPropertyElementMaster};

  err = CMIOObjectGetPropertyDataSize(kCMIOObjectSystemObject, &prop, 0, nil,
                                      &dataSize);
  if (err != kCMIOHardwareNoError) {

#ifdef DEBUG
    NSLog(@"getVideoDevicesCount(): error: %d", err);
#endif

    return err;
  }

  *count = dataSize / sizeof(CMIODeviceID);

  return err;
}

OSStatus getVideoDevices(int count, CMIODeviceID *devices) {
  OSStatus err;
  UInt32 dataSize = 0;
  UInt32 dataUsed = 0;

  CMIOObjectPropertyAddress prop = {kCMIOHardwarePropertyDevices,
                                    kCMIOObjectPropertyScopeGlobal,
                                    kCMIOObjectPropertyElementMaster};

  err = CMIOObjectGetPropertyDataSize(kCMIOObjectSystemObject, &prop, 0, nil,
                                      &dataSize);
  if (err != kCMIOHardwareNoError) {

#ifdef DEBUG
    NSLog(@"getVideoDevices(): get data size error: %d", err);
#endif

    return err;
  }

  err = CMIOObjectGetPropertyData(kCMIOObjectSystemObject, &prop, 0, nil,
                                  dataSize, &dataUsed, devices);
  if (err != kCMIOHardwareNoError) {

#ifdef DEBUG
    NSLog(@"getVideoDevices(): get data error: %d", err);
#endif

    return err;
  }

  return err;
}

OSStatus getVideoDeviceUID(CMIOObjectID device, NSString **uid) {
  OSStatus err;
  UInt32 dataSize = 0;
  UInt32 dataUsed = 0;

  CMIOObjectPropertyAddress prop = {kCMIODevicePropertyDeviceUID,
                                    kCMIOObjectPropertyScopeWildcard,
                                    kCMIOObjectPropertyElementWildcard};

  err = CMIOObjectGetPropertyDataSize(device, &prop, 0, nil, &dataSize);
  if (err != kCMIOHardwareNoError) {

#ifdef DEBUG
    NSLog(@"getVideoDeviceUID(): get data size error: %d", err);
#endif

    return err;
  }

  CFStringRef uidStringRef = NULL;
  err = CMIOObjectGetPropertyData(device, &prop, 0, nil, dataSize, &dataUsed,
                                  &uidStringRef);
  if (err != kCMIOHardwareNoError) {

#ifdef DEBUG
    NSLog(@"getVideoDeviceUID(): get data error: %d", err);
#endif

    return err;
  }

    *uid = (__bridge NSString *)uidStringRef;

  return err;
}

void getVideoDeviceDescription(NSString *uid, NSString **description) {
  AVCaptureDevice *avDevice = [AVCaptureDevice deviceWithUniqueID:uid];
  if (avDevice == nil) {
    *description = [NSString
        stringWithFormat:@"%@ (failed to get AVCaptureDevice with device UID)",
                         uid];
  } else {
    *description =
        [NSString stringWithFormat:
                      @"%@ (name: '%@', model: '%@', is exclusively used: %d)",
                      uid, [avDevice localizedName], [avDevice modelID],
                      [avDevice isInUseByAnotherApplication]];
  }
}

OSStatus getVideoDeviceIsUsed(CMIOObjectID device, int *isUsed) {
  OSStatus err;
  UInt32 dataSize = 0;
  UInt32 dataUsed = 0;

  CMIOObjectPropertyAddress prop = {kCMIODevicePropertyDeviceIsRunningSomewhere,
                                    kCMIOObjectPropertyScopeWildcard,
                                    kCMIOObjectPropertyElementWildcard};

  err = CMIOObjectGetPropertyDataSize(device, &prop, 0, nil, &dataSize);
  if (err != kCMIOHardwareNoError) {

#ifdef DEBUG
    NSLog(@"getVideoDeviceIsUsed(): get data size error: %d", err);
#endif

    return err;
  }

  err = CMIOObjectGetPropertyData(device, &prop, 0, nil, dataSize, &dataUsed,
                                  isUsed);
  if (err != kCMIOHardwareNoError) {

#ifdef DEBUG
    NSLog(@"getVideoDeviceIsUsed(): get data error: %d", err);
#endif

    return err;
  }

  return err;
}

OSStatus IsCameraOn(int *on) {


    *on = 0;
    
#ifdef DEBUG
  NSLog(@"C.IsCameraOn()");
#endif


  OSStatus err;

  int count;
  err = getVideoDevicesCount(&count);
  if (err) {

#ifdef DEBUG
    NSLog(@"C.IsCameraOn(): failed to get devices count, error: %d", err);
#endif

    return err;
  }

  CMIODeviceID *devices = (CMIODeviceID *)malloc(count * sizeof(*devices));
  if (devices == NULL) {

#ifdef DEBUG
    NSLog(@"C.IsCameraOn(): failed to allocate memory, device count: %d", count);
#endif

         
    return VD_ERR_OUT_OF_MEMORY;
  }

  err = getVideoDevices(count, devices);
  if (err) {

#ifdef DEBUG
    NSLog(@"C.IsCameraOn(): failed to get devices, error: %d", err);
#endif

    free(devices);
    devices = NULL;
    return err;
  }

#ifdef DEBUG

  NSLog(@"C.IsCameraOn(): found devices: %d", count);
#endif

  if (count > 0) {

#ifdef DEBUG
    NSLog(@"C.IsCameraOn(): # | is used | description");
#endif

  }

  int failedDeviceCount = 0;
  int ignoredDeviceCount = 0;

  for (int i = 0; i < count; i++) {
    CMIOObjectID device = devices[i];

    NSString *uid;
    err = getVideoDeviceUID(device, &uid);
    if (err) {
      failedDeviceCount++;

#ifdef DEBUG
      NSLog(@"C.IsCameraOn(): %d | -       | failed to get device UID: %d", i, err);
#endif

           
      continue;
    }

    if (isIgnoredDeviceUID(uid)) {
      ignoredDeviceCount++;
      continue;
    }

    int isDeviceUsed;
    err = getVideoDeviceIsUsed(device, &isDeviceUsed);
    if (err) {
      failedDeviceCount++;

#ifdef DEBUG
      NSLog(@"C.IsCameraOn(): %d | -       | failed to get device status: %d", i, err);
#endif

           
      continue;
    }

    NSString *description;
    getVideoDeviceDescription(uid, &description);

#ifdef DEBUG

    NSLog(@"C.IsCameraOn(): %d | %s     | %@", i,isDeviceUsed == 0 ? "NO " : "YES", description);

#endif


    if (isDeviceUsed != 0) {
      (*on)++;
    }
  }

  free(devices);
  devices = NULL;

#ifdef DEBUG

  NSLog(@"C.IsCameraOn(): failed devices: %d", failedDeviceCount);

  NSLog(@"C.IsCameraOn(): ignored devices (always on): %d", ignoredDeviceCount);

  NSLog(@"C.IsCameraOn(): is any camera on: %s", *on == 0 ? "NO" : "YES");
  
#endif


  if (failedDeviceCount == count) {
    return VD_ERR_ALL_DEVICES_FAILED;
  }

  return VD_ERR_NO_ERR;
}
