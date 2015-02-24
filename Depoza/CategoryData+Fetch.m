//
//  CategoryData+Fetch.m
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "CategoryData+Fetch.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"

@implementation CategoryData (Fetch)

+ (NSInteger)countForCategoriesInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];

    NSError *error = nil;
    NSUInteger count = [context countForFetchRequest:fetch error:&error];
    if (error) {
        NSLog(@"Could't fetc for count number of categories: %@", [error localizedDescription]);
    }
    return count;
}

+ (NSInteger)nextId {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    NSInteger idValue = [userDefaults integerForKey:@"categoryId"];
    [userDefaults setInteger:idValue + 1 forKey:@"categoryId"];
    [userDefaults synchronize];

    return idValue;
}

+ (void)synchronizeUserDefaultsWithNumberCategories:(NSInteger)categories {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:categories forKey:@"categoryId"];
    [defaults synchronize];
}

+ (CategoryData *)categoryDataWithName:(NSString *)name managedObjectContext:(NSManagedObjectContext *)context {
    CategoryData *categoryData = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([CategoryData class]) inManagedObjectContext:context];
    categoryData.idValue = @([self nextId]);
    categoryData.title = name;
    
    return categoryData;
}

+ (NSArray *)getAllCategoriesInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];

    NSError *error = nil;
    NSArray *foundCategories = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"***Error: %@", [error localizedDescription]);
    }
    NSParameterAssert(foundCategories.count > 0);

    return foundCategories;
}

+ (CategoryData *)categoryFromTitle:(NSString *)category context:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];

    NSExpression *title = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(title))];
    NSExpression *categoryName = [NSExpression expressionForConstantValue:category];
    NSPredicate *predicate = [NSComparisonPredicate
                              predicateWithLeftExpression:title
                              rightExpression:categoryName
                              modifier:NSDirectPredicateModifier
                              type:NSEqualToPredicateOperatorType
                              options:0];
    fetchRequest.predicate = predicate;

    NSError *error;
    NSArray *foundCategory = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"***Error: %@", [error localizedDescription]);
    }

    NSParameterAssert([foundCategory count] == 1);
    NSParameterAssert([[foundCategory firstObject]isKindOfClass:[CategoryData class]]);

    return [foundCategory firstObject];
}

+ (NSArray *)getAllTitlesInContext:(NSManagedObjectContext *)context {
    NSArray *categories = [CategoryData getAllCategoriesInContext:context];
    NSMutableArray *titles = [NSMutableArray arrayWithCapacity:[categories count]];

    for (CategoryData *category in categories) {
        [titles addObject:category.title];
    }
    return [NSArray arrayWithArray:titles];
}

+ (NSArray *)getCategoriesWithExpensesBetweenMonthOfDate:(NSDate *)date managedObjectContext:(NSManagedObjectContext *)context {
    NSArray *days = [date getFirstAndLastDaysInTheCurrentMonth];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(SUBQUERY(expense, $x, ($x.dateOfExpense >= %@) AND ($x.dateOfExpense <= %@)).@count > 0)", [days firstObject], [days lastObject]];

    NSError *error = nil;
    NSArray *categories = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"Error occured %@", [error localizedDescription]);
    }
    return categories;
}

@end
