//
//  LivuConfigViewController.h
//  Livu
//
//  Created by Steve on 12/27/10.
//  Copyright 2010 Steve McFarlin. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LivuConfigViewController : UIViewController <UIAlertViewDelegate, UIScrollViewDelegate> {

    UIScrollView    *scrollView;
    
    // Network Config
    UITextField     *address;
    UITextField     *port;
    UITextField     *application;
    UITextField     *user;
    UITextField     *pass;
    UITextField     *frameRate;
    UITextField     *keyFrameInterval;
    UIButton        *useTCP;
    UIButton        *autoBitrateAdjust;
	UIButton		*autoRestart;
    UILabel         *bitrateSettingLabel;
    // Video Config
    UIButton        *broadcastOptionButtton;
	UIButton		*broadcastTypeButton;
    int				broadcastOption;
	int				broadcastType;
        
@private

    //UITableViewCell *customCell;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIButton *broadcastOptionButtton;
@property (nonatomic, retain) IBOutlet UIButton *videoOrientation;
@property (nonatomic, retain) IBOutlet UIButton *useTCP;
@property (nonatomic, retain) IBOutlet UIButton *autoBitrateAdjust;
@property (nonatomic, retain) IBOutlet UIButton *broadcastTypeButton;
@property (nonatomic, retain) IBOutlet UIButton *autoRestart;
@property (nonatomic, retain) IBOutlet UITextField *address, *port, *application, *user, *pass;
@property (nonatomic, retain) IBOutlet UITextField *frameRate, *keyFrameInterval;
@property (nonatomic, retain) IBOutlet UILabel *bitrateSettingLabel;


/*!
 @abstract Select the next quality setting
*/
- (IBAction) nextQualitySetting: (id) sender;

- (IBAction) nextBroadcastType: (id) sender;

/*!
 @abstract Toggle transport
 */
- (IBAction) toggleTransport:(UIButton*) sender;

- (IBAction) toggleButton:(UIButton*) sender;

/*!
 @abstract Closes the keyboard.
 */
- (IBAction) backgroundTap:(id) sender;


/*!
 @abstract Close and save the configuration.
 */
- (IBAction) close:(id) sender;

- (IBAction) cancel:(id) sender;

/*!
 @abstract Value changed. This is used for the searchableFields.
 */
- (IBAction) textFieldValueChanged:(UITextField*)textField;

- (void) loadConfig;
- (void) saveConfig;

@end
