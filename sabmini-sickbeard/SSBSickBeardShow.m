//
//  SSBSickBeardShow.m
//  SickBeard Demo App
//
//  Created by Stefan Klein Nulent on 16-12-12.
//  Copyright (c) 2012 Stefan Klein Nulent. All rights reserved.
//

#import "SSBSickBeardShow.h"
#import "SSBSickBeardConnector.h"
#import "SSBSickBeardResult.h"
#import "SSBSharedServer.h"
#import "SSBSickBeardServer.h"
#import "SSBSickBeardEpisode.h"

@interface SSBSickBeardShow()

- (void)setAttributes:(NSDictionary *)attributes;

@end

@implementation SSBSickBeardShow
@synthesize identifier, air_by_date, airs, show_cache, flatten_folders, genre, language, location, network, next_ep_airdate, paused, quality, quality_details, season_list, show_name, status, tvrage_id, tvrage_name;

- (id)initWithAttributes:(NSDictionary *)attributes showIdentifier:(NSString *)showIdentifier
{
    self = [super init];
    if (self) {
        self.identifier = showIdentifier;
        [self setAttributes:attributes];
    }
    
    return self;
}

- (void)setAttributes:(NSDictionary *)attributes
{
    if ([attributes objectForKey:@"air_by_date"]) self.air_by_date = [[attributes objectForKey:@"air_by_date"] boolValue];
    if ([attributes objectForKey:@"airs"]) self.airs = [attributes objectForKey:@"airs"];
    if ([attributes objectForKey:@"cache"]) self.show_cache = [attributes objectForKey:@"cache"];
    if ([attributes objectForKey:@"flatten_folders"]) self.flatten_folders = [[attributes objectForKey:@"flatten_folders"] boolValue];
    if ([attributes objectForKey:@"genre"]) self.genre = [attributes objectForKey:@"genre"];
    if ([attributes objectForKey:@"language"]) self.language = [attributes objectForKey:@"language"];
    if ([attributes objectForKey:@"location"]) self.location = [attributes objectForKey:@"location"];
    if ([attributes objectForKey:@"network"]) self.network = [attributes objectForKey:@"network"];
    if ([attributes objectForKey:@"next_ep_airdate"]) self.next_ep_airdate = [attributes objectForKey:@"next_ep_airdate"];
    if ([attributes objectForKey:@"paused"]) self.paused = [[attributes objectForKey:@"paused"] boolValue];
    if ([attributes objectForKey:@"quality"]) self.quality = [attributes objectForKey:@"quality"];
    if ([attributes objectForKey:@"quality_details"]) self.quality_details = [attributes objectForKey:@"quality_details"];
    if ([attributes objectForKey:@"season_list"]) self.season_list = [[attributes objectForKey:@"season_list"] sortedArrayUsingSelector:@selector(compare:)];
    if ([attributes objectForKey:@"show_name"]) self.show_name = [attributes objectForKey:@"show_name"];
    if ([attributes objectForKey:@"status"]) self.status = [attributes objectForKey:@"status"];
    if ([attributes objectForKey:@"tvrage_id"]) self.tvrage_id = [attributes objectForKey:@"tvrage_id"];
    if ([attributes objectForKey:@"tvrage_name"]) self.tvrage_name = [attributes objectForKey:@"tvrage_name"];
}

- (void)getFullDetails:(SSBSickBeardShowRequestResponseBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@show&tvdbid=%@", [[SSBSharedServer sharedServer].server urlString], self.identifier]];
    
    SSBSickBeardConnector *connector = [[SSBSickBeardConnector alloc] initWithURL:url];
    [connector getData:^(NSDictionary *data) {
        [self setAttributes:[data objectForKey:@"data"]];
        complete([[SSBSickBeardResult alloc] initWithAttributes:data]);
    } onFailure:^(SSBSickBeardResult *result) {
        failed(result);
    }];
}

// Delete the show from SickBeard
- (void)deleteShow:(SSBSickBeardShowRequestResponseBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@show.delete&tvdbid=%@", [[SSBSharedServer sharedServer].server urlString], self.identifier]];
    SSBSickBeardConnector *connector = [[SSBSickBeardConnector alloc] initWithURL:url];
    [connector getData:^(NSDictionary *data) {
        complete([[SSBSickBeardResult alloc] initWithAttributes:data]);
    } onFailure:^(SSBSickBeardResult *result) {
        failed(result);
    }];
}

- (void)getEpisodesForSeason:(int)season onComplete:(SSBSickBeardShowRequestDataBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@show.seasons&tvdbid=%@&season=%i", [[SSBSharedServer sharedServer].server urlString], self.identifier, season]];
    SSBSickBeardConnector *connector = [[SSBSickBeardConnector alloc] initWithURL:url];
    [connector getData:^(NSDictionary *data) {

        NSMutableArray *episodes = [NSMutableArray array];
        NSArray *unsortedArray = [NSArray arrayWithArray:[[data objectForKey:@"data"] allKeys]];
        NSArray *keys = [unsortedArray sortedArrayUsingComparator:^(id firstObject, id secondObject) {
            return [((NSString *)firstObject) compare:((NSString *)secondObject) options:NSNumericSearch];
        }];
        
        for (NSString *key in keys) {
            NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[[data objectForKey:@"data"] objectForKey:key]];
            [attributes setObject:key forKey:@"episode"];
            SSBSickBeardEpisode *episode = [[SSBSickBeardEpisode alloc] initWithAttributes:attributes];
            episode.tvdbid = self.identifier;
            [episodes addObject:episode];
        }
        
        complete([NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:episodes, [data objectForKey:@"message"], [data objectForKey:@"result"], nil] forKeys:[NSArray arrayWithObjects:@"results", @"message", @"result", nil]]);
    } onFailure:^(SSBSickBeardResult *result) {
        failed(result);
    }];
}

- (void)pause:(SSBSickBeardShowRequestResponseBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@show.pause&tvdbid=%@&pause=1", [[SSBSharedServer sharedServer].server urlString], self.identifier]];
    SSBSickBeardConnector *connector = [[SSBSickBeardConnector alloc] initWithURL:url];
    [connector getData:^(NSDictionary *data) {
        complete([[SSBSickBeardResult alloc] initWithAttributes:data]);
    } onFailure:^(SSBSickBeardResult *result) {
        failed(result);
    }];
}

- (void)unpause:(SSBSickBeardShowRequestResponseBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@show.pause&tvdbid=%@&pause=0", [[SSBSharedServer sharedServer].server urlString], self.identifier]];
    SSBSickBeardConnector *connector = [[SSBSickBeardConnector alloc] initWithURL:url];
    [connector getData:^(NSDictionary *data) {
        complete([[SSBSickBeardResult alloc] initWithAttributes:data]);
    } onFailure:^(SSBSickBeardResult *result) {
        failed(result);
    }];
}

- (void)refresh:(SSBSickBeardShowRequestResponseBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@show.refresh&tvdbid=%@", [[SSBSharedServer sharedServer].server urlString], self.identifier]];
    SSBSickBeardConnector *connector = [[SSBSickBeardConnector alloc] initWithURL:url];
    [connector getData:^(NSDictionary *data) {
        complete([[SSBSickBeardResult alloc] initWithAttributes:data]);
    } onFailure:^(SSBSickBeardResult *result) {
        failed(result);
    }];
}

- (void)update:(SSBSickBeardShowRequestResponseBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@show.update&tvdbid=%@", [[SSBSharedServer sharedServer].server urlString], self.identifier]];
    SSBSickBeardConnector *connector = [[SSBSickBeardConnector alloc] initWithURL:url];
    [connector getData:^(NSDictionary *data) {
        complete([[SSBSickBeardResult alloc] initWithAttributes:data]);
    } onFailure:^(SSBSickBeardResult *result) {
        failed(result);
    }];
}

- (void)getBanner:(SSBSickBeardShowRequestImageBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@show.getbanner&tvdbid=%@", [[SSBSharedServer sharedServer].server urlString], self.identifier]];
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    UIImage *banner = [UIImage imageWithData:imageData];
    
    complete(banner);
}

- (void)getPoster:(SSBSickBeardShowRequestImageBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@show.getposter&tvdbid=%@", [[SSBSharedServer sharedServer].server urlString], self.identifier]];
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    UIImage *poster = [UIImage imageWithData:imageData];
    
    complete(poster);
}






// Checks if the poster/banner SickBeard's image cache is valid
- (void)cache:(SSBSickBeardShowRequestResponseBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@show.cache&tvdbid=%@", [[SSBSharedServer sharedServer].server urlString], self.identifier]];
    SSBSickBeardConnector *connector = [[SSBSickBeardConnector alloc] initWithURL:url];
    [connector getData:^(NSDictionary *data) {
        complete([[SSBSickBeardResult alloc] initWithAttributes:data]);
    } onFailure:^(SSBSickBeardResult *result) {
        failed(result);
    }];
}

- (void)getQuality:(SSBSickBeardShowRequestResponseBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@show.getquality&tvdbid=%@", [[SSBSharedServer sharedServer].server urlString], self.identifier]];
    SSBSickBeardConnector *connector = [[SSBSickBeardConnector alloc] initWithURL:url];
    [connector getData:^(NSDictionary *data) {
        complete([[SSBSickBeardResult alloc] initWithAttributes:data]);
    } onFailure:^(SSBSickBeardResult *result) {
        failed(result);
    }];
}







- (void)getSeasonList:(NSString *)sort onComplete:(SSBSickBeardShowRequestResponseBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@show.seasonlist&tvdbid=%@", [[SSBSharedServer sharedServer].server urlString], self.identifier]];
    SSBSickBeardConnector *connector = [[SSBSickBeardConnector alloc] initWithURL:url];
    [connector getData:^(NSDictionary *data) {
        complete([[SSBSickBeardResult alloc] initWithAttributes:data]);
    } onFailure:^(SSBSickBeardResult *result) {
        failed(result);
    }];
}

- (void)setQuality:(NSArray *)initial archive:(NSArray *)archive onComplete:(SSBSickBeardShowRequestResponseBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    
}

- (void)getStatistics:(SSBSickBeardShowRequestResponseBlock)complete onFailure:(SSBSickBeardShowRequestResponseBlock)failed
{
    
}



@end
