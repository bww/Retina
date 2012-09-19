// 
// Copyright (c) 2012 Wolter Group New York, Inc., All rights reserved.
// Retina Image Conversion Tool
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
//   * Redistributions of source code must retain the above copyright notice, this
//     list of conditions and the following disclaimer.
// 
//   * Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//     
//   * Neither the names of Brian William Wolter, Wolter Group New York, nor the
//     names of its contributors may be used to endorse or promote products derived
//     from this software without specific prior written permission.
//     
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
// OF THE POSSIBILITY OF SUCH DAMAGE.
// 

#import <getopt.h>

static const char *kCommand = NULL;

enum {
  kWGOptionNone           = 0,
  kWGOptionCreateRetina   = 1 << 0,
  kWGOptionCreateStandard = 1 << 1,
  kWGOptionForce          = 1 << 2,
  kWGOptionPlan           = 1 << 3,
  kWGOptionVerbose        = 1 << 4
};

#define VERBOSE(options, format...)  if((options & kWGOptionVerbose) == kWGOptionVerbose){ fprintf(stdout, ##format); }

void WGProcessPath(int options, NSString *path);
void WGProcessDirectory(int options, NSString *path);
void WGProcessFile(int options, NSString *path);
void WGCreateScaledAsset(int options, CGFloat scale, NSString *input, NSString *output);
void WGUsage(FILE *stream);
void WGHelp(FILE *stream);

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    int options = kWGOptionNone;
    
    if((kCommand = strrchr(argv[0], '/')) == NULL){
      kCommand = argv[0];
    }else{
      kCommand++; // skip the '/' character
    }
    
    static struct option longopts[] = {
      { "create-retina",    no_argument,  NULL,   'R' },  // create scaled-up retina versions
      { "create-standard",  no_argument,  NULL,   'S' },  // create scaled-down standard versions
      { "force",            no_argument,  NULL,   'f' },  // force assets to be created even if they already exist
      { "plan",             no_argument,  NULL,   'p' },  // display which files would be created, but don't actually create them
      { "verbose",          no_argument,  NULL,   'v' },  // be more verbose
      { "help",             no_argument,  NULL,   'h' },  // display help information
      { NULL,               0,            NULL,    0  }
    };
    
    int flag;
    while((flag = getopt_long(argc, (char **)argv, "RSfpvh", longopts, NULL)) != -1){
      switch(flag){
        
        case 'R':
          options |= kWGOptionCreateRetina;
          break;
          
        case 'S':
          options |= kWGOptionCreateStandard;
          break;
          
        case 'f':
          options |= kWGOptionForce;
          break;
          
        case 'p':
          options |= kWGOptionPlan;
          break;
          
        case 'v':
          options |= kWGOptionVerbose;
          break;
          
        case 'h':
          WGHelp(stderr);
          return 0;
          
        default:
          WGUsage(stderr);
          return 0;
          
      }
    }
    
    argv += optind;
    argc -= optind;
    
    if(argc < 1){
      WGUsage(stderr);
      return 0;
    }
    
    for(int i = 0; i < argc; i++){
      NSString *path = [[NSString alloc] initWithUTF8String:argv[i]];
      WGProcessPath(options, path);
      [path release];
    }
    
  }
  return 0;
}

void WGProcessPath(int options, NSString *path) {
  BOOL directory;
  
  if(![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&directory]){
    fprintf(stderr, "%s: * * * no such file at path: %s\n", kCommand, [path UTF8String]);
    return;
  }
  
  VERBOSE(options, "%s: processing: %s\n", kCommand, [path UTF8String]);
  
  if(directory){
    WGProcessDirectory(options, path);
  }else{
    WGProcessFile(options, path);
  }
  
}

void WGProcessDirectory(int options, NSString *path) {
  NSError *error = nil;
  
  NSArray *files;
  if((files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error]) == nil){
    fprintf(stderr, "%s: * * * unable to list directory at path: %s: %s\n", kCommand, [path UTF8String], [[error localizedDescription] UTF8String]);
  }
  
  for(NSString *file in files){
    WGProcessFile(options, [path stringByAppendingPathComponent:file]);
  }
  
}

void WGProcessFile(int options, NSString *path) {
  @autoreleasepool {
    
    if([[path pathExtension] caseInsensitiveCompare:@"png"] != NSOrderedSame){
      VERBOSE(options, "%s: skipping unsupported file: %s\n", kCommand, [path UTF8String]);
      return;
    }
    
    NSString *base = [path stringByDeletingPathExtension];
    
    if([base length] > 3 && [base hasSuffix:@"@2x"]){
      if((options & kWGOptionCreateStandard) == kWGOptionCreateStandard){
        NSString *output = [[base substringWithRange:NSMakeRange(0, [base length] - 3 /* "@2x" */)] stringByAppendingPathExtension:@"png"];
        if((options & kWGOptionForce) == kWGOptionForce || ![[NSFileManager defaultManager] fileExistsAtPath:output]){
          fprintf(stdout, "%s: creating standard version: %s ==> %s\n", kCommand, [path UTF8String], [output UTF8String]);
          WGCreateScaledAsset(options, 0.5, path, output);
        }else{
          VERBOSE(options, "%s: standard version already exists; skipping: %s\n", kCommand, [path UTF8String]);
        }
      }
    }else{
      if((options & kWGOptionCreateRetina) == kWGOptionCreateRetina){
        NSString *output = [[base stringByAppendingString:@"@2x"] stringByAppendingPathExtension:@"png"];
        if((options & kWGOptionForce) == kWGOptionForce || ![[NSFileManager defaultManager] fileExistsAtPath:output]){
          fprintf(stdout, "%s: creating retina version: %s ==> %s\n", kCommand, [path UTF8String], [output UTF8String]);
          WGCreateScaledAsset(options, 2, path, output);
        }else{
          VERBOSE(options, "%s: retina version already exists; skipping: %s\n", kCommand, [path UTF8String]);
        }
      }
    }
    
  }
}

void WGCreateScaledAsset(int options, CGFloat scale, NSString *input, NSString *output) {
  CGImageSourceRef source = NULL;
  CGImageRef image = NULL;
  
  if((source = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:input], NULL)) == NULL){
    fprintf(stderr, "%s: * * * unable to create image source: %s\n", kCommand, [input UTF8String]);
    goto inputerror;
  }
  
  if(CGImageSourceGetCount(source) < 1){
    fprintf(stderr, "%s: * * * image source contains no images: %s\n", kCommand, [input UTF8String]);
    goto inputerror;
  }
  
  if((image = CGImageSourceCreateImageAtIndex(source, 0, NULL)) == NULL){
    fprintf(stderr, "%s: * * * unable to create image from source: %s\n", kCommand, [input UTF8String]);
    goto inputerror;
  }
  
  CGSize size = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
  size_t width  = (size_t)ceil(size.width  * scale);
  size_t height = (size_t)ceil(size.height * scale);
  
  VERBOSE(options, "%s: scaling image [%dx%d to %dx%d]: %s\n", kCommand, (int)size.width, (int)size.height, (int)width, (int)height, [input UTF8String]);
  
  if((options & kWGOptionPlan) != kWGOptionPlan){
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    
    CGContextRef context = NULL;
    CGImageRef scaled = NULL;
    CGImageDestinationRef destination = NULL;
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, width * bytesPerPixel, colorspace, kCGImageAlphaPremultipliedLast);
    if(colorspace) CFRelease(colorspace);
    
    if(context == NULL){
      fprintf(stderr, "%s: * * * unable to create graphics context: %s\n", kCommand, [input UTF8String]);
      goto outputerror;
    }
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    
    if((scaled = CGBitmapContextCreateImage(context)) == NULL){
      fprintf(stderr, "%s: * * * unable to create image from graphics context: %s\n", kCommand, [input UTF8String]);
      goto outputerror;
    }
    
    if((destination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:output], kUTTypePNG, 1, NULL)) == NULL){
      fprintf(stderr, "%s: * * * unable to create image destination: %s\n", kCommand, [input UTF8String]);
      goto outputerror;
    }
    
    CGImageDestinationAddImage(destination, scaled, NULL);
    
    if(!CGImageDestinationFinalize(destination)){
      fprintf(stderr, "%s: * * * unable to finalize image destination: %s\n", kCommand, [input UTF8String]);
      goto outputerror;
    }
    
outputerror:
    if(context) CFRelease(context);
    if(scaled) CFRelease(scaled);
    if(destination) CFRelease(destination);
  }
  
inputerror:
  if(source) CFRelease(source);
  if(image) CFRelease(image);
  
}

void WGUsage(FILE *stream) {
  fputs(
    "Retina Image Conversion Tool\n"
    "Copyright (c) 2012 Wolter Group New York, Inc.\n"
    "\n"
    "Usage: retina -[R|S] [options] <path> [<path> ...]\n"
    " Help: retina -h\n"
    "\n"
    "Specify image files to convert or specify directories to convert all suitable\n"
    "files in that directory, non-recursively. Retina will convert any PNG files it\n"
    "encounters that do not already have a counterpart.\n"
    "\n"
    , stream
  );
}

void WGHelp(FILE *stream) {
  WGUsage(stream);
  fputs(
    "OPTIONS:\n"
    "\n"
    "  --create-retina    -R    Create scaled-up retina versions of all standard\n"
    "                           resolution images encountered.\n"
    "  --create-standard  -S    Create scaled-down standard versions of all retina\n"
    "                           resolution images encountered.\n"
    "  --force            -f    Force the creation of counterpart images even if\n"
    "                           they already exist.\n"
    "  --plan             -p    Display the files which would be created but don't\n"
    "                           actually perform any conversion.\n"
    "  --verbose          -v    Be more verbose. Additional information about the\n"
    "                           conversion process is displayed.\n"
    "  --help             -h    Display this help information and exit.\n"
    "\n"
    "You must use either -R or -S (or both) in order to do anything useful.\n"
    "\n"
    , stream
  );
}

