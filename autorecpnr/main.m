#include <stdio.h>
#import <MRYIPCCenter.h>
#import <Foundation/Foundation.h>

//Shamelessly stolen from StackOverflow. https://stackoverflow.com/questions/2501033/nsstring-hex-to-bytes
//This converts a string with hex data (such as @"37C3F2AE") into a real NSData* object (i.e. <37c3 f2ae>)
//Used for converting the signature string in the REG-RESP SMS into an NSData* object
@interface NSString (NSStringHexToBytes)
-(NSData*) hexToBytes ;
@end

@implementation NSString (NSStringHexToBytes)
-(NSData*) hexToBytes {
  NSMutableData* data = [NSMutableData data];
  int idx;
  for (idx = 0; idx+2 <= self.length; idx+=2) {
    NSRange range = NSMakeRange(idx, 2);
    NSString* hexStr = [self substringWithRange:range];
    NSScanner* scanner = [NSScanner scannerWithString:hexStr];
    unsigned int intValue;
    [scanner scanHexInt:&intValue];
    [data appendBytes:&intValue length:1];
  }
  return data;
}
@end

int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
		printf("AutoPNRGateway: Hello world!\n");

		while(true) {
			NSURL *url = [NSURL URLWithString:@"https://calm-dream-b6f7.jakecrow.workers.dev/regresp"];
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

			NSURLSessionConfiguration *defaultSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
			NSURLSession *session = [NSURLSession sessionWithConfiguration:defaultSessionConfiguration];
			NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
				if (error) {
					NSLog(@"%@", error);
				} else {
					NSString *msgText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

					if (![msgText isEqualToString:@"null"]) {
						NSLog(@"Found REG-RESP - %@", msgText);

						//Uses a regular expression to extract the relevant fields from the received SMS: the phone number (starting with n=)
						//  and the signature (starting with s=)
						NSRegularExpression *regRespRegex = [NSRegularExpression regularExpressionWithPattern:@"REG-RESP\\?v=\\d;r=\\d+;n=([\\+\\d]+);s=([0-9A-F]+)" options:0 error:nil];
						NSTextCheckingResult *result = [regRespRegex firstMatchInString:msgText options:0 range:NSMakeRange(0, [msgText length])];

						if (result) {
							NSLog(@"Regex match: %@", result);
						} else {
							NSLog(@"No match found");
						}

						if (result.numberOfRanges < 2) {
							NSLog(@"Not enough matches found!");
						}

						//Extracts the phone number from the regex
						NSRange phoneNumberRange = [result rangeAtIndex:1];
						NSString *phoneNumberMatch = [msgText substringWithRange:phoneNumberRange];
						NSLog(@"Phone number: %@", phoneNumberMatch);

						//Extracts the signature from the regex
						NSRange signatureRange = [result rangeAtIndex:2];
						NSString *signatureMatch = [msgText substringWithRange:signatureRange];
						NSLog(@"Signature: %@", signatureMatch);

						//Converts the signature to NSData* using the hexToBytes method defined above.
						NSData* byteSignature = [signatureMatch hexToBytes];

						NSLog(@"Converted signature to bytes: %@", byteSignature);

						//Sets up the MRYIPC client so this method (running inside SMSApplication) can call the emulateReceivedResponsePNR
						//  method located in the IDSPhoneNumberValidationStateMachine
						NSLog(@"PNRGateway: Setting up MRYIPC client");
						MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"dev.altavision.SIMLessPNR"];
						NSLog(@"PNRGateway: Got reference to dev.altavision.SIMLessPNR: %@", center);

						// [center addTarget:^id() {
						//     // Inline block code
						//     NSLog(@"Block executed");
						//
						// } forSelector:@selector(testIPC:)];
						NSLog(@"PNRGateway: Testing IPC center...");
						// [center callExternalMethod:@selector(testIPC:) withArguments:nil];
						NSLog(@"PNRGateway: Finished testing IPC center");

						//Calls the emulateReceivedResponsePNR method inside the state machine
						// NSLog(@"PNRGateway: Calling external method handleIncomingSMSForPhoneNumber...");
						[center callExternalMethod:@selector(performResponse:) withArguments:@[phoneNumberMatch, byteSignature]];
						// NSLog(@"PNRGateway: Called external method handleIncomingSMSForPhoneNumber");

						NSLog(@".");
						NSLog(@"Done.");
					} else {
						NSLog(@"No new requests");
					}
				}
			}];
			[dataTask resume];

			[NSThread sleepForTimeInterval:3.0];
		}

		return 0;
	}
}
