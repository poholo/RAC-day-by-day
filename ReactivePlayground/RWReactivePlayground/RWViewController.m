//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import  <ReactiveCocoa.h>

@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

//@property (nonatomic) BOOL passwordIsValid;
//@property (nonatomic) BOOL usernameIsValid;
@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
  [super viewDidLoad];
    /*
    [self.usernameTextField.rac_textSignal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
  
    [self.passwordTextField.rac_textSignal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
     */
    
    /*
    [[[self.usernameTextField.rac_textSignal
      map:^id(NSString* value) {
          return @(value.length);
      }]
      filter:^BOOL(NSNumber *length) {
        return [length integerValue] > 6;
      }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
      }];
     */
    
    RACSignal *validUserSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidUsername:text]);
    }];
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidPassword:text]);
    }];
    
    
    /*
    [[validPasswordSignal map:^id(NSNumber *passwordValid) {
            return [passwordValid boolValue] ? [UIColor clearColor] : [UIColor yellowColor];
        }]
        subscribeNext:^(UIColor *bgColor) {
            self.passwordTextField.backgroundColor = bgColor;
        }];
    
    [[validUserSignal map:^id(NSNumber *usernameValid) {
            return [usernameValid boolValue] ? [UIColor clearColor] : [UIColor orangeColor];
        }] subscribeNext:^(UIColor *bgColor) {
            self.usernameTextField.backgroundColor = bgColor;
        }];
     */
    
    // has better method
    /*
     从概念上来说，就是把之前信号的输出应用到输入框的backgroundColor属性上。但是上面的用法不是很好。
     
     幸运的是，ReactiveCocoa提供了一个宏来更好的完成上面的事情。把下面的代码直接加到viewDidLoad中两个信号的代码后面：
     */
    
    /**
        RAC宏允许直接把信号的输出应用到对象的属性上。RAC宏有两个参数，第一个是需要设置属性值的对象，第二个是属性名。每次信号产生一个next事件，传递过来的值都会应用到该属性上。
     */
    
//    RAC(self.usernameTextField, backgroundColor) = [validUserSignal map:^id(NSNumber *usernameValid) {
//        return  [usernameValid boolValue] ? [UIColor greenColor] : [UIColor purpleColor];
//    }];
//    
//    RAC(self.passwordTextField, backgroundColor) = [validPasswordSignal map:^id(NSNumber *passwordValid) {
//        return [passwordValid boolValue] ? [UIColor orangeColor] : [UIColor redColor];
//    }];
    
    
    /**
     你是否好奇为什么要创建两个分开的validPasswordSignal和validUsernameSignal呢，而不是每个输入框一个单独的管道呢？（？）稍安勿躁，答案就在下面。
     
     原文：Are you wondering why you created separate validPasswordSignal and validUsernameSignal signals, as opposed to a single fluent pipeline for each text field? Patience dear reader, the method behind this madness will become clear shortly!
     
     聚合信号
     
     目前在应用中，登录按钮只有当用户名和密码输入框的输入都有效时才工作。现在要把这里改成响应式的。
     
     现在的代码中已经有可以产生用户名和密码输入框是否有效的信号了——validUsernameSignal和validPasswordSignal了。现在需要做的就是聚合这两个信号来决定登录按钮是否可用。
     */
    
//    RACSignal * signUpActiveSignal = [RACSignal combineLatest:@[validUserSignal, validPasswordSignal] reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid) {
//        return @([usernameValid boolValue] && [passwordValid boolValue]);
//    }];
    
    //每次这两个源信号的任何一个产生新值时，reduce block都会执行，block的返回值会发给下一个信号。
//    [[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
//        NSLog(@"btn click");
//    }];


    /*
    [[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] map:^id(id value) {
            return [self signInSignal];
        }]
        subscribeNext:^(id x) {
            NSLog(@"sigin %@", [x class]);
        }];
    
     */
    
    
    [[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] flattenMap:^RACStream *(id value) {
        return [self signInSignal];
    }]
     subscribeNext:^(NSNumber*signedIn){
         BOOL success =[signedIn boolValue];
         self.signInFailureText.hidden = success;
         if(success){
             [self performSegueWithIdentifier:@"signInSuccess" sender:self];
         }
     }];

    /*
    [[[self.signInButton
       rac_signalForControlEvents:UIControlEventTouchUpInside]
      flattenMap:^id(id x){
          return [self signInSignal];
      }]
     subscribeNext:^(id x){
         NSLog(@"Sign in result: %@", x);
     }];
     */

  // initially hide the failure message
  self.signInFailureText.hidden = YES;
}

- (RACSignal *)signInSignal {
    return [RACSignal createSignal:^RACDisposable *(id subscriber){
        [self.signInService
         signInWithUsername:self.usernameTextField.text
         password:self.passwordTextField.text
         complete:^(BOOL success){
             [subscriber sendNext:@(success)];
             [subscriber sendCompleted];
         }];
        return nil;
    }];
}

- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 5;
}

@end
