// #import <cocoa/cocoa.h>
#import <CoreLocation/CoreLocation.h>
#include <node.h>

// https://raw.github.com/evanphx/lost/master/ext/lost/core_loc.m
using namespace v8;

@interface LLHolder : NSObject {
    double latitude;
    double longitude;
    int worked;
}

- (void)reset;
- (int)useData;
- (void)latitude:(double*)lat longitude:(double*)log;

- (void)logLonLat:(CLLocation*)location;
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
    - (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
    @end

@implementation LLHolder
- (void)reset {
    worked = 0;
}

- (int)useData {
    return worked;
}

- (void)latitude:(double*)lat longitude:(double*)log {
    *lat = latitude;
    *log = longitude;
}

- (void)logLonLat:(CLLocation*)location {
    worked = 1;
    CLLocationCoordinate2D coordinate = location.coordinate;
    latitude = coordinate.latitude;
    longitude = coordinate.longitude;

    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [self logLonLat:newLocation];
        [pool drain];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    latitude = 0.0;
    longitude = 0.0;
    CFRunLoopStop(CFRunLoopGetCurrent());
}
@end

id g_lm = nil;

int int_coreloc_enable() {
  if ([CLLocationManager locationServicesEnabled]) {
		g_lm = [[CLLocationManager alloc] init];
    return 1;
  }
  return 0;
}

int int_coreloc_get(double* lat, double* log) {
  LLHolder* obj = [[LLHolder alloc] init];
	[g_lm setDelegate:obj];
	[g_lm startUpdatingLocation];

  CFRunLoopRun();

  [g_lm stopUpdatingLocation];

  if([obj useData] == 1) {
    [obj latitude: lat longitude: log];
    [obj release];
    return 1;
  }

  [obj release];
  return 0;
}

Handle<Value> GetLocation(const Arguments& args) {
    HandleScope scope;

    double lat, log;
    if (!int_coreloc_enable()) {
        return scope.Close(Null());
    }
    if (!int_coreloc_get(&lat, &log)) {
        return scope.Close(Null());
    } else {
        Local<Array> arr(Array::New(2));
        arr->Set(0, Number::New(log));
        arr->Set(1, Number::New(lat));
        return scope.Close(arr);
    }
}

void RegisterModule(v8::Handle<v8::Object> target) {
    target->Set(String::NewSymbol("getLocation"),
        FunctionTemplate::New(GetLocation)->GetFunction());
}

NODE_MODULE(node_corelocation, RegisterModule);
