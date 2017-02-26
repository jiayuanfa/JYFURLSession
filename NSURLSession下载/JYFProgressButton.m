//
//  JYFProgressButton.m
//  NSURLSession下载
//
//  Created by mac on 2017/2/20.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "JYFProgressButton.h"

@implementation JYFProgressButton

- (void)setProgress:(float)progress{
    _progress = progress;
    
    // 设置Title
    [self setTitle:[NSString stringWithFormat:@"%.02f%%",_progress * 100] forState:(UIControlStateNormal)];
    
    // 刷图视图 会调用drawRect
    [self setNeedsDisplay];
}

/*
 写一个宏 myMIN(a,b) 返回最小值
 写一个宏 myMIN3(a,b,c) 返回最小值
 */

#define myMIN(a,b) (((a) < (b))?(a):(b))
#define myMIN3(a,b,c) myMIN(myMIN(a,b,),c)

#pragma mark -- 画个圆
- (void)drawRect:(CGRect)rect{
    
    // 圆心
    CGPoint center = CGPointMake(rect.size.width / 2, rect.size.height / 2);
    // 半径
//    CGFloat r = (rect.size.height > rect.size.width)? rect.size.width * 0.4 : rect.size.height * 0.4;
    CGFloat r = myMIN(rect.size.width, rect.size.height) * 0.4;
    // 从什么地方开始
    CGFloat startAng = - M_PI_2; // 从180度开始
    // 到什么地方结束
    CGFloat endAng = self.progress * 2 * M_PI + startAng; // 两倍的PI就是一个圆
    /*
     1.圆心
     2.半径
     3.起始角度
     4.结束角度
     5.顺时针
     */
    // 使用贝塞尔曲线来进行绘制
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:r startAngle:startAng endAngle:endAng clockwise:YES];
    
    // 设置线条宽度
    path.lineWidth = 10;
    // 设置线条风格
    path.lineCapStyle = kCGLineCapRound;
    // 填充颜色
    [[UIColor blueColor] setStroke];
    // 绘制路径
    [path stroke];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
