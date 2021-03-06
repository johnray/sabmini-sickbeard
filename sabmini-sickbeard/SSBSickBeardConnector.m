//
//  SSBSickBeardConnector.m
//
//  Created by Stefan Klein Nulent on 17-12-12.
//  Copyright (c) 2012 Stefan Klein Nulent. All rights reserved.
//

#import "SSBSickBeardConnector.h"
#import "SBJson.h"
#import "SSBSickBeardResult.h"

@interface SSBSickBeardConnector() <SBJsonStreamParserAdapterDelegate>

@property (nonatomic, strong) SBJsonStreamParser *parser;
@property (nonatomic, strong) SBJsonStreamParserAdapter *adapter;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURL *connectionUrl;
@property (nonatomic, copy) SSBSickBeardConnectorFinishedBlock clb;
@property (nonatomic, copy) SSBSickBeardConnectorFailedBlock clbFailed;

@end

@implementation SSBSickBeardConnector

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        self.connectionUrl = url;
        self.adapter = [[SBJsonStreamParserAdapter alloc] init];
        self.adapter.delegate = self;
        self.parser = [[SBJsonStreamParser alloc] init];
        self.parser.delegate = self.adapter;
        self.parser.supportMultipleDocuments = YES;
    }
    
    return self;
}

- (void)getData:(SSBSickBeardConnectorFinishedBlock)callback onFailure:(SSBSickBeardConnectorFailedBlock)failure
{
    self.clb = callback;
    self.clbFailed = failure;
    NSURLRequest *request = [NSURLRequest requestWithURL:self.connectionUrl];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

#pragma mark -
#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    SBJsonStreamParserStatus status = [self.parser parse:data];
	
	if (status == SBJsonStreamParserError) {
        NSString *msg = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        self.clbFailed([[SSBSickBeardResult alloc] initWithAttributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:msg, NO, nil] forKeys:[NSArray arrayWithObjects:@"message", @"result", nil]]]);
	} else if (status == SBJsonStreamParserWaitingForData) {
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    self.clbFailed([[SSBSickBeardResult alloc] initWithAttributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Error connecting to the Sick Beard server!", @"Error connecting to the Sick Beard server message", NO, nil] forKeys:[NSArray arrayWithObjects:@"message", @"result", nil]]]);
    
    self.connection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.connection = nil;
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	
	[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
	
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

#pragma mark -
#pragma mark SBJsonStreamParserAdapterDelegate methods

- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
}

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
    
    if ([[dict objectForKey:@"result"] isEqualToString:@"success"]) {
        self.clb(dict);
    }
    else {
        self.clbFailed([[SSBSickBeardResult alloc] initWithAttributes:dict]);
    }
    
}

@end
