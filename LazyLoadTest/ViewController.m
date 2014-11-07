//
//  ViewController.m
//  LazyLoadTest
//
//  Created by Inder Kumar Rathore on 07/11/14.
//
//

#import "ViewController.h"
#import "IconDownloader.h"
#import "MLog.h"
#import "CustomCell.h"

#define kIconBaseUrl @"http://placehold.it/200&text="
#define kTempCacheDir @"cache-images"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableDictionary *newsFeedImages;
@property (nonatomic, strong) NSMutableDictionary *imageDownloadsInProgress;

@end

@implementation ViewController
- (void)viewDidLoad {
  [super viewDidLoad];
  
  //allocate the ivar
  self.newsFeedImages = [[NSMutableDictionary alloc] init];
  self.imageDownloadsInProgress = [[NSMutableDictionary alloc] init];
}


#pragma mark - UITableView delegates/datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 90.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
  
  NSString *imageName = [NSString stringWithFormat:@"%ld.png", indexPath.row];
  UIImage *image = [self.newsFeedImages objectForKey:imageName];
  if (!image) {
    //image is not in memory chek on storage media
    NSString *imagePath = [IconDownloader imagePath:kTempCacheDir iconName:imageName];
    image = [UIImage imageWithContentsOfFile:imagePath];
    
    if (!image) {
      //still not present, download the image from the server
      if (self.tableView.dragging == NO && self.tableView.decelerating == NO) {
        [self startIconDownload:imageName forIndexPath:indexPath];
      }
      //set the placeholder image
      image = [UIImage imageNamed:@"placeholder.png"];
    }
    else {
      //image was in storage now load it to memory
      [self.newsFeedImages setObject:image forKey:imageName];
    }
  }
  cell.iconImageView.image = image;
  
  return cell;
}

#pragma mark - Table cell image support

// -------------------------------------------------------------------------------
//	startIconDownload:forIndexPath:
// -------------------------------------------------------------------------------
- (void)startIconDownload:(NSString *)iconName forIndexPath:(NSIndexPath *)indexPath {
  IconDownloader *iconDownloader = [self.imageDownloadsInProgress objectForKey:iconName];
  if (iconDownloader == nil) {
    iconDownloader = [[IconDownloader alloc] init];
    iconDownloader.iconUrl = [NSString stringWithFormat:@"%@%@", kIconBaseUrl, iconName];
    iconDownloader.iconName = iconName;
    iconDownloader.iconDirName = kTempCacheDir;
    
    [iconDownloader setCompletionHandler:^{
      MLog(@"%@ - Section:%ld Row:%ld", indexPath, (long)indexPath.section, (long)indexPath.row);
      
      CustomCell *cell = (CustomCell *)[self.tableView cellForRowAtIndexPath:indexPath];
      MLog(@"cell - %@", cell);
      if (cell) {
        IconDownloader *blockIconDownloader = [self.imageDownloadsInProgress objectForKey:iconName];
        // Display the newly loaded image
        NSString *imagePath = [blockIconDownloader imagePath];
        MLog(@"image path-%@", imagePath);
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        if (image) {
          //save the image for further use
          [self.newsFeedImages setObject:image forKey:iconName];
          //Set the image to cell, I'm using animation here you can directly set it.
          [UIView transitionWithView:cell.iconImageView
                            duration:0.4f
                             options:UIViewAnimationOptionTransitionCrossDissolve
                          animations:^{
                            cell.iconImageView.image = image;
                          } completion:nil];
        }
      }

      // Remove the IconDownloader from the in progress list.
      // This will result in it being deallocated.
      [self.imageDownloadsInProgress removeObjectForKey:iconName];
    }];
    
    [self.imageDownloadsInProgress setObject:iconDownloader forKey:iconName];
    [iconDownloader startDownload];
  }
}

// -------------------------------------------------------------------------------
//	loadImagesForOnscreenRows
//  This method is used in case the user scrolled into a set of cells that don't
//  have their app icons yet.
// -------------------------------------------------------------------------------
- (void)loadImagesForOnscreenRows {
  NSArray *visibleCellIndexPaths = [self.tableView indexPathsForVisibleRows];
  for (NSIndexPath *indexPath in visibleCellIndexPaths) {
    NSString *imageName = [NSString stringWithFormat:@"%ld.png", indexPath.row];
    UIImage *image = [self.newsFeedImages objectForKey:imageName];
    
    // Avoid the app icon download if the category already has an icon
    if (!image) {
      [self startIconDownload:imageName forIndexPath:indexPath];
    }
  }
}

#pragma mark - UIScrollViewDelegate

// -------------------------------------------------------------------------------
//	scrollViewDidEndDragging:willDecelerate:
//  Load images for all onscreen rows when scrolling is finished.
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (!decelerate)
  {
    [self loadImagesForOnscreenRows];
  }
}

// -------------------------------------------------------------------------------
//	scrollViewDidEndDecelerating:
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  [self loadImagesForOnscreenRows];
}



@end
