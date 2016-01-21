//
//  iPhone OAuth Starter Kit
//
//  Supported providers: LinkedIn (OAuth 1.0a)
//
//  Lee Whitney
//  http://whitneyland.com
//
#import <Foundation/NSNotificationQueue.h>
#import "OAuthLoginView.h"


#define API_KEY_LENGTH 12
#define SECRET_KEY_LENGTH 16

//
// OAuth steps for version 1.0a:
//
//  1. Request a "request token"
//  2. Show the user a browser with the LinkedIn login page
//  3. LinkedIn redirects the browser to our callback URL
//  4  Request an "access token"
//
@implementation OAuthLoginView

@synthesize requestToken, accessToken, profile, consumer;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initLinkedInApi];
    [addressBar setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    [self requestTokenFromProvider];
}

-(IBAction)signInWithLinkedIn
{
    
}

- (void)requestTokenFromProvider
{
    OAMutableURLRequest *request =
    [[OAMutableURLRequest alloc] initWithURL:requestTokenURL
                                    consumer:self.consumer
                                       token:nil
                                    callback:linkedInCallbackURL
                           signatureProvider:nil];
    
    [request setHTTPMethod:@"POST"];
    
    OARequestParameter *nameParam = [[OARequestParameter alloc] initWithName:@"scope"
                                                                       value:@"r_basicprofile+rw_nus+first-name+headline+picture-url"];
    NSArray *params = [NSArray arrayWithObjects:nameParam, nil];
    [request setParameters:params];
    OARequestParameter * scopeParameter=[OARequestParameter requestParameter:@"scope" value:@"r_basicprofile rw_nus first-name headline picture-url"];
    
    [request setParameters:[NSArray arrayWithObject:scopeParameter]];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestTokenResult:didFinish:)
                  didFailSelector:@selector(requestTokenResult:didFail:)];
}

//
// OAuth step 1b:
//
// When this method is called it means we have successfully received a request token.
// We then show a webView that sends the user to the LinkedIn login page.
// The request token is added as a parameter to the url of the login page.
// LinkedIn reads the token on their end to know which app the user is granting access to.
//
- (void)requestTokenResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    if (ticket.didSucceed == NO)
        return;
    
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
    self.requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
    [self allowUserToLogin];
}

- (void)requestTokenResult:(OAServiceTicket *)ticket didFail:(NSData *)error
{
    NSLog(@"%@",[error description]);
}

//
// OAuth step 2:
//
// Show the user a browser displaying the LinkedIn login page.
// They type username/password and this is how they permit us to access their data
// We use a UIWebView for this.
//
// Sending the token information is required, but in this one case OAuth requires us
// to send URL query parameters instead of putting the token in the HTTP Authorization
// header as we do in all other cases.
//
- (void)allowUserToLogin
{
    NSString *userLoginURLWithToken = [NSString stringWithFormat:@"%@?oauth_token=%@",
                                       userLoginURLString, self.requestToken.key];
    
    userLoginURL = [NSURL URLWithString:userLoginURLWithToken];
    NSURLRequest *request = [NSMutableURLRequest requestWithURL: userLoginURL];
    [webView loadRequest:request];
}


//
// OAuth step 3:
//
// This method is called when our webView browser loads a URL, this happens 3 times:
//
//      a) Our own [webView loadRequest] message sends the user to the LinkedIn login page.
//
//      b) The user types in their username/password and presses 'OK', this will submit
//         their credentials to LinkedIn
//
//      c) LinkedIn responds to the submit request by redirecting the browser to our callback URL
//         If the user approves they also add two parameters to the callback URL: oauth_token and oauth_verifier.
//         If the user does not allow access the parameter user_refused is returned.
//
//      Example URLs for these three load events:
//          a) https://www.linkedin.com/uas/oauth/authorize?oauth_token=<token value>
//
//          b) https://www.linkedin.com/uas/oauth/authorize/submit   OR
//             https://www.linkedin.com/uas/oauth/authenticate?oauth_token=<token value>&trk=uas-continue
//
//          c) hdlinked://linkedin/oauth?oauth_token=<token value>&oauth_verifier=63600     OR
//             hdlinked://linkedin/oauth?user_refused
//
//
//  We only need to handle case (c) to extract the oauth_verifier value
//
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *url = request.URL;
	NSString *urlString = url.absoluteString;
    
    addressBar.text = urlString;
    [activityIndicator startAnimating];
    
    BOOL requestForCallbackURL = ([urlString rangeOfString:linkedInCallbackURL].location != NSNotFound);
    if ( requestForCallbackURL )
    {
        BOOL userAllowedAccess = ([urlString rangeOfString:@"user_refused"].location == NSNotFound);
        if ( userAllowedAccess )
        {
            [self.requestToken setVerifierWithUrl:url];
            [self accessTokenFromProvider];
        }
        else
        {
            // User refused to allow our app access
            // Notify parent and close this view
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"loginViewDidFinish"
             object:self
             userInfo:nil];
            
            [self dismissModalViewControllerAnimated:YES];
        }
    }
    else
    {
        // Case (a) or (b), so ignore it
    }
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [activityIndicator stopAnimating];
}

//
// OAuth step 4:
//
- (void)accessTokenFromProvider
{
    OAMutableURLRequest *request =
    [[OAMutableURLRequest alloc] initWithURL:accessTokenURL
                                    consumer:self.consumer
                                       token:self.requestToken
                                    callback:nil
                           signatureProvider:nil];
    
    [request setHTTPMethod:@"POST"];
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(accessTokenResult:didFinish:)
                  didFailSelector:@selector(accessTokenResult:didFail:)];
}

- (void)accessTokenResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
    
    BOOL problem = ([responseBody rangeOfString:@"oauth_problem"].location != NSNotFound);
    if ( problem )
    {
        NSLog(@"Request access token failed.");
        NSLog(@"%@",responseBody);
    }
    else
    {
        self.accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
    }
    // Notify parent and close this view
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"loginViewDidFinish"
     object:self];
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)accessTokenResult:(OAServiceTicket *)ticket didFail:(NSData *)data
{
    [self dismissModalViewControllerAnimated:YES];
}

//
//  This api consumer data could move to a provider object
//  to allow easy switching between LinkedIn, Twitter, etc.
//
- (void)initLinkedInApi
{
    apikey = @"c8dwtidmv6t2";
    secretkey = @"87qsAJkUY8bBYWAl";
    
    self.consumer = [[OAConsumer alloc] initWithKey:apikey
                                             secret:secretkey
                                              realm:@"http://api.linkedin.com/"];
    
    requestTokenURLString = @"https://api.linkedin.com/uas/oauth/requestToken";
    accessTokenURLString = @"https://api.linkedin.com/uas/oauth/accessToken";
    userLoginURLString = @"https://www.linkedin.com/uas/oauth/authorize";
    linkedInCallbackURL = @"hdlinked://linkedin/oauth";
    
    requestTokenURL = [NSURL URLWithString:requestTokenURLString];
    accessTokenURL = [NSURL URLWithString:accessTokenURLString];
    userLoginURL = [NSURL URLWithString:userLoginURLString];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


@end
