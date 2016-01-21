//
//  UploadToParseViewController.m
//  Mitek Hackathon
//
//  Created by Aryaman Sharda on 4/26/14.
//  Copyright (c) 2014 Tempest Vision. All rights reserved.
//

#import "UploadToParseViewController.h"
#import "OAConsumer.h"
#import "linkedInViewController.h"
@interface UploadToParseViewController ()
{
    bool canSearch;
}
@end

@implementation UploadToParseViewController
{
    PFFile *imageFile;
}
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
    
    
   
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSDictionary *oAuthConsumerInfo = [prefs objectForKey:@"oAuthConsumerInfo"];
    NSDictionary *oAuthTokenInfo = [prefs objectForKey:@"oAuthTokenInfo"];
    
    NSString *consumerKey = [oAuthConsumerInfo objectForKey:@"key"];
    NSString *secretKey = [oAuthConsumerInfo objectForKey:@"secret"];
    NSString *realmKey = [oAuthConsumerInfo objectForKey:@"realm"];
    
    self.consumer = [[OAConsumer alloc] initWithKey:consumerKey secret:secretKey realm:realmKey];
    
    NSString *tokenKey = [oAuthTokenInfo objectForKey:@"key"];
    NSString *tokenSecret = [oAuthTokenInfo objectForKey:@"secret"];
    
    self.accessToken = [[OAToken alloc] initWithKey:tokenKey secret:tokenSecret];
    
    if(self.consumer && self.accessToken)
        canSearch=TRUE;
    

    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:[prefs objectForKey:@"rawImageText"] options:0];
    
    [imgView setImage:[UIImage imageWithData:decodedData]];
    imageFile = [PFFile fileWithName:@"image.png" data:decodedData];
    
    txtName.delegate = self;
    txtEmail.delegate = self;
    txtCompany.delegate = self;
    txtName.delegate = self;
    txtAddress.delegate = self;
    txtTitle.delegate = self;

}

-(void)viewDidAppear:(BOOL)animated
{
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    NSArray *myArray = [prefs objectForKey:@"formattedArray"];
    
    [txtName setText:[myArray objectAtIndex:0]];
    [txtCompany setText:[myArray objectAtIndex:1]];
    [txtTitle setText:[myArray objectAtIndex:2]];
    [txtEmail setText:[myArray objectAtIndex:3]];
    [txtPhone setText:[myArray objectAtIndex:4]];
    [txtAddress setText:[myArray objectAtIndex:5]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [txtName resignFirstResponder];
    [txtCompany resignFirstResponder];
    [txtTitle resignFirstResponder];
    [txtEmail resignFirstResponder];
    [txtPhone resignFirstResponder];
    [txtAddress resignFirstResponder];
}

-(IBAction)takeToParse
{
    if(canSearch)
        [self profileApiCall];
    
    PFUser *curr  = [PFUser currentUser];
    PFObject *uploadCard = [PFObject objectWithClassName:@"Card"];
    uploadCard[@"Name"] = txtName.text;
    uploadCard[@"Email"] = txtEmail.text;
    uploadCard[@"Title"] = txtTitle.text;
    uploadCard[@"Phone"] = txtPhone.text;
    uploadCard[@"Address"] = txtAddress.text;
    uploadCard[@"Company"] = txtCompany.text;
    uploadCard[@"Notes"] = @"";
     
    
    [uploadCard saveInBackground];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:[prefs objectForKey:@"rawImageText"] options:0];
    UIImage *final = [self reduced:[UIImage imageWithData:decodedData]];
    NSData *parseData = UIImagePNGRepresentation(final);
    imageFile = [PFFile fileWithName:@"image.png" data:parseData];

    PFObject *userPhoto = [PFObject objectWithClassName:@"UserPhoto"];
    userPhoto[@"imageName"] = txtName.text;
    userPhoto[@"imageFile"] = imageFile;
    userPhoto[@"Owner"] = curr.objectId;
    [userPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
    {
        if(!error)
        {
            NSLog(@"Finished uploading");
        }
    }];

    [self performSegueWithIdentifier:@"backToHome" sender:nil];
}
-(UIImage*)reduced:(UIImage*)fullImage
{
    UIImage *originalImage = fullImage;
    CGSize destinationSize = CGSizeMake(fullImage.size.width/2, fullImage.size.height/2);
    UIGraphicsBeginImageContext(destinationSize);
    [originalImage drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)profileApiCall
{
    
    NSURL *url = [NSURL URLWithString:@"http://api.linkedin.com/v1/people-search:(people:(id,first-name,last-name,picture-url,headline),num-results)?first-name=aryaman&last-name=sharda"];
    
    OAMutableURLRequest *request =
    [[OAMutableURLRequest alloc] initWithURL:url
                                    consumer:self.consumer
                                       token:self.accessToken
                                    callback:nil
                           signatureProvider:nil];
    
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(profileApiCallResult:didFinish:)
                  didFailSelector:nil];
    
}


- (void)profileApiCallResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    NSError *error = nil;
    NSDictionary *profile = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    
    if (profile)
    {
        if([profile objectForKey:@"numResults"]>0)
        {
            NSDictionary *people = [profile objectForKey:@"people"];
            NSArray *values = [people objectForKey:@"values"];
            NSDictionary *person = [values objectAtIndex:0];
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:person forKey:@"rawLinkedIn"];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
