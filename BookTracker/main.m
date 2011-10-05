//
//  main.m
//  BookTracker
//
//  Created by Jon Doud on 9/21/11.
//  Copyright (c) 2011 Itinerant Software Solutions. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MacRuby/MacRuby.h>

int main(int argc, char *argv[])
{
    return macruby_main("rb_main.rb", argc, argv);
}
