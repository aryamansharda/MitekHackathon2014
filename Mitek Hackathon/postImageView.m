//
//  postImageView.m
//  Mitek Hackathon
//
//  Created by Aryaman Sharda on 4/26/14.
//  Copyright (c) 2014 Tempest Vision. All rights reserved.
//

#import "postImageView.h"

@interface postImageView ()

@end

@implementation postImageView
{
    int validEntry;
    int position;
    NSString *rawText;
    NSMutableArray *arrayToPass;
    NSMutableArray *rawLines;
    
    NSString *strName;
    NSString *strCompany;
    NSString *strTitle;
    NSString *strEmail;
    NSString *strPhone;
    NSString *strAddress;
    
    
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    strName = @"";
    strCompany = @"";
    strTitle = @"";
    strEmail  = @"";
    strPhone = @"";
    strAddress = @"";
    
    arrayToPass = [[NSMutableArray alloc] init];
    rawLines = [[NSMutableArray alloc] init];
    position = 0;
    validEntry = 0;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:[prefs objectForKey:@"rawImageText"] options:0];
    UIImage *rawImage = [UIImage imageWithData:decodedData];
    [passedImage setImage:rawImage];
    
    rawText = [prefs objectForKey:@"rawOCRText"];
     NSLog(@"Raw Text: %@",rawText);
    
    if(txtData.text.length == 0)
    {
        
        
               
        [self performSegueWithIdentifier:@"retryPhoto" sender:nil];
        
        
    }
    rawLines = [[rawText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
    [self progress:YES];
    
}
-(void)progress:(BOOL)doStuff
{
      NSLog(@"Position: %d", position);
      NSLog(@"valid entry: %d", validEntry);
    
      if([rawLines count] > position)
      {
        [txtData setText:[rawLines objectAtIndex:position]];
        
       }
       else
       {
            [arrayToPass addObject:strName];
            [arrayToPass addObject:strCompany];
            [arrayToPass addObject:strTitle];
            [arrayToPass addObject:strEmail];
            [arrayToPass addObject:strPhone];
            [arrayToPass addObject:strAddress];
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:arrayToPass forKey:@"formattedArray"];
            [self performSegueWithIdentifier:@"transitionToEdit" sender:nil];
            NSLog(@"Done");
       }
}

-(IBAction)progressThrough:(id)sender
{
    if ([sender tag] == 1)
    {
        position++;
        [self progress:NO];
        
    }
    else
    {
        if([sender tag] == 2)
        {
            strName = [NSString stringWithFormat:@"%@ %@",strName,txtData.text];
        }
        if([sender tag] == 3)
        {
            strCompany  = [NSString stringWithFormat:@"%@ %@",strCompany,txtData.text];
        }
        if([sender tag] == 4)
        {
            strTitle  = [NSString stringWithFormat:@"%@ %@",strTitle,txtData.text];
            NSLog(@"Str Title: %@", strTitle);
        }
        if([sender tag] == 5)
        {
            strEmail = [NSString stringWithFormat:@"%@ %@",strEmail,txtData.text];
        }
        if([sender tag] == 6)
        {
            strPhone = [NSString stringWithFormat:@"%@ %@",strPhone,txtData.text];
        }
        if([sender tag] == 7)
        {
            strAddress = [NSString stringWithFormat:@"%@ %@",strAddress,txtData.text];
        }
        validEntry++;
        position++;
        [self progress:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (BOOL)prefersStatusBarHidden {
    return YES;
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
