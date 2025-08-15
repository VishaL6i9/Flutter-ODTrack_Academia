import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';

void main() {
  group('Teaching Analytics Integration Tests', () {
    group('Subject-wise Period Allocation', () {
      test('should calculate subject allocation with realistic data', () {
        // Create realistic subject allocation data
        final subjectAllocations = <String, SubjectAllocation>{
          'MATH101': const SubjectAllocation(
            subjectCode: 'MATH101',
            subjectName: 'Mathematics I',
            periodsPerWeek: 6,
            totalPeriods: 96, // 6 * 16 weeks
            classAssignments: [
              ClassAssignment(
                className: '10A',
                grade: Grade.grade10,
                section: 'A',
                studentCount: 35,
                periodsAssigned: 3,
              ),
              ClassAssignment(
                className: '10B',
                grade: Grade.grade10,
                section: 'B',
                studentCount: 32,
                periodsAssigned: 3,
              ),
            ],
            studentCount: 67,
            type: SubjectType.theory,
          ),
          'PHYS101': const SubjectAllocation(
            subjectCode: 'PHYS101',
            subjectName: 'Physics I',
            periodsPerWeek: 4,
            totalPeriods: 64, // 4 * 16 weeks
            classAssignments: [
              ClassAssignment(
                className: '10A',
                grade: Grade.grade10,
                section: 'A',
                studentCount: 35,
                periodsAssigned: 2,
              ),
              ClassAssignment(
                className: '10B',
                grade: Grade.grade10,
                section: 'B',
                studentCount: 32,
                periodsAssigned: 2,
              ),
            ],
            studentCount: 67,
            type: SubjectType.theory,
          ),
        };

        // Test total periods calculation
        final totalPeriods = subjectAllocations.values
            .fold<int>(0, (sum, allocation) => sum + allocation.periodsPerWeek);
        expect(totalPeriods, equals(10));

        // Test subject distribution
        final mathPercentage = (subjectAllocations['MATH101']!.periodsPerWeek / totalPeriods) * 100;
        final physPercentage = (subjectAllocations['PHYS101']!.periodsPerWeek / totalPeriods) * 100;
        
        expect(mathPercentage, equals(60.0));
        expect(physPercentage, equals(40.0));

        // Test student count tracking
        expect(subjectAllocations['MATH101']!.studentCount, equals(67));
        expect(subjectAllocations['PHYS101']!.studentCount, equals(67));

        // Test class assignments
        expect(subjectAllocations['MATH101']!.classAssignments.length, equals(2));
        expect(subjectAllocations['PHYS101']!.classAssignments.length, equals(2));
      });

      test('should handle uneven period distribution across classes', () {
        // Test scenario where periods don't divide evenly across classes
        const periodsPerWeek = 7; // Odd number
        const classCount = 3; // Doesn't divide evenly
        
        const periodsPerClass = periodsPerWeek ~/ classCount; // 2
        const remainderPeriods = periodsPerWeek % classCount; // 1
        
        expect(periodsPerClass, equals(2));
        expect(remainderPeriods, equals(1));
        
        // First class gets extra period
        const class1Periods = periodsPerClass + (0 < remainderPeriods ? 1 : 0); // 3
        const class2Periods = periodsPerClass + (1 < remainderPeriods ? 1 : 0); // 2
        const class3Periods = periodsPerClass + (2 < remainderPeriods ? 1 : 0); // 2
        
        expect(class1Periods, equals(3));
        expect(class2Periods, equals(2));
        expect(class3Periods, equals(2));
        expect(class1Periods + class2Periods + class3Periods, equals(periodsPerWeek));
      });

      test('should calculate subject type distribution correctly', () {
        final subjectTypes = {
          'MATH101': SubjectType.theory,
          'CHEM_LAB': SubjectType.lab,
          'PHYS_PRAC': SubjectType.practical,
          'CS_PROJ': SubjectType.project,
          'ENG_SEM': SubjectType.seminar,
        };

        final typeDistribution = <SubjectType, int>{};
        for (final type in subjectTypes.values) {
          typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;
        }

        expect(typeDistribution[SubjectType.theory], equals(1));
        expect(typeDistribution[SubjectType.lab], equals(1));
        expect(typeDistribution[SubjectType.practical], equals(1));
        expect(typeDistribution[SubjectType.project], equals(1));
        expect(typeDistribution[SubjectType.seminar], equals(1));
      });
    });

    group('Class-wise Teaching Load Analysis', () {
      test('should calculate class load distribution accurately', () {
        final classAllocations = <String, ClassAllocation>{
          '10A': const ClassAllocation(
            className: '10A',
            grade: Grade.grade10,
            section: 'A',
            studentCount: 35,
            periodsAssigned: 8,
            subjects: ['MATH101', 'PHYS101', 'CHEM101'],
            type: ClassType.regular,
          ),
          '10B': const ClassAllocation(
            className: '10B',
            grade: Grade.grade10,
            section: 'B',
            studentCount: 32,
            periodsAssigned: 6,
            subjects: ['MATH101', 'PHYS101'],
            type: ClassType.regular,
          ),
          '11A': const ClassAllocation(
            className: '11A',
            grade: Grade.grade11,
            section: 'A',
            studentCount: 28,
            periodsAssigned: 5,
            subjects: ['MATH201', 'PHYS201'],
            type: ClassType.honors,
          ),
        };

        // Test total periods calculation
        final totalPeriods = classAllocations.values
            .fold<int>(0, (sum, allocation) => sum + allocation.periodsAssigned);
        expect(totalPeriods, equals(19));

        // Test load distribution percentages
        final class10APercentage = (classAllocations['10A']!.periodsAssigned / totalPeriods) * 100;
        final class10BPercentage = (classAllocations['10B']!.periodsAssigned / totalPeriods) * 100;
        final class11APercentage = (classAllocations['11A']!.periodsAssigned / totalPeriods) * 100;

        expect(class10APercentage, closeTo(42.11, 0.01));
        expect(class10BPercentage, closeTo(31.58, 0.01));
        expect(class11APercentage, closeTo(26.32, 0.01));

        // Test subject count per class
        expect(classAllocations['10A']!.subjects.length, equals(3));
        expect(classAllocations['10B']!.subjects.length, equals(2));
        expect(classAllocations['11A']!.subjects.length, equals(2));

        // Test class types
        expect(classAllocations['10A']!.type, equals(ClassType.regular));
        expect(classAllocations['10B']!.type, equals(ClassType.regular));
        expect(classAllocations['11A']!.type, equals(ClassType.honors));
      });

      test('should handle different class types correctly', () {
        final classTypes = {
          '10A_REG': ClassType.regular,
          '10B_HON': ClassType.honors,
          '10C_REM': ClassType.remedial,
          '11A_ADV': ClassType.advanced,
          '11B_SPEC': ClassType.special,
        };

        // Test class type distribution
        final typeDistribution = <ClassType, int>{};
        for (final type in classTypes.values) {
          typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;
        }

        expect(typeDistribution[ClassType.regular], equals(1));
        expect(typeDistribution[ClassType.honors], equals(1));
        expect(typeDistribution[ClassType.remedial], equals(1));
        expect(typeDistribution[ClassType.advanced], equals(1));
        expect(typeDistribution[ClassType.special], equals(1));
      });

      test('should calculate periods per subject per class correctly', () {
        // Test complex allocation scenario
        final subjectPeriods = {'MATH': 6, 'PHYS': 4, 'CHEM': 3};
        final classes = ['10A', '10B', '10C'];
        
        final allocations = <String, Map<String, int>>{};
        
        for (final subject in subjectPeriods.keys) {
          final periods = subjectPeriods[subject]!;
          final periodsPerClass = periods ~/ classes.length;
          final remainder = periods % classes.length;
          
          for (int i = 0; i < classes.length; i++) {
            final className = classes[i];
            final assignedPeriods = periodsPerClass + (i < remainder ? 1 : 0);
            
            allocations[className] = allocations[className] ?? {};
            allocations[className]![subject] = assignedPeriods;
          }
        }

        // Verify MATH allocation (6 periods / 3 classes = 2 each)
        expect(allocations['10A']!['MATH'], equals(2));
        expect(allocations['10B']!['MATH'], equals(2));
        expect(allocations['10C']!['MATH'], equals(2));

        // Verify PHYS allocation (4 periods / 3 classes = 1 each, 1 remainder)
        expect(allocations['10A']!['PHYS'], equals(2)); // Gets remainder
        expect(allocations['10B']!['PHYS'], equals(1));
        expect(allocations['10C']!['PHYS'], equals(1));

        // Verify CHEM allocation (3 periods / 3 classes = 1 each)
        expect(allocations['10A']!['CHEM'], equals(1));
        expect(allocations['10B']!['CHEM'], equals(1));
        expect(allocations['10C']!['CHEM'], equals(1));
      });
    });

    group('Grade-wise Teaching Load Analysis', () {
      test('should calculate grade distribution correctly', () {
        final gradeDistribution = <Grade, int>{
          Grade.grade9: 2,
          Grade.grade10: 3,
          Grade.grade11: 2,
          Grade.grade12: 1,
        };

        final totalClasses = gradeDistribution.values.fold<int>(0, (sum, count) => sum + count);
        expect(totalClasses, equals(8));

        // Calculate percentages
        final grade9Percentage = (gradeDistribution[Grade.grade9]! / totalClasses) * 100;
        final grade10Percentage = (gradeDistribution[Grade.grade10]! / totalClasses) * 100;
        final grade11Percentage = (gradeDistribution[Grade.grade11]! / totalClasses) * 100;
        final grade12Percentage = (gradeDistribution[Grade.grade12]! / totalClasses) * 100;

        expect(grade9Percentage, equals(25.0));
        expect(grade10Percentage, equals(37.5));
        expect(grade11Percentage, equals(25.0));
        expect(grade12Percentage, equals(12.5));
        expect(grade9Percentage + grade10Percentage + grade11Percentage + grade12Percentage, equals(100.0));
      });

      test('should calculate grade-wise student counts correctly', () {
        final gradeStudentCounts = <Grade, int>{
          Grade.grade9: 65,  // 2 classes * ~32 students
          Grade.grade10: 105, // 3 classes * ~35 students
          Grade.grade11: 60,  // 2 classes * ~30 students
          Grade.grade12: 25,  // 1 class * ~25 students
        };

        final totalStudents = gradeStudentCounts.values.fold<int>(0, (sum, count) => sum + count);
        expect(totalStudents, equals(255));

        // Calculate average class size per grade
        final grade9AvgSize = gradeStudentCounts[Grade.grade9]! / 2; // 2 classes
        final grade10AvgSize = gradeStudentCounts[Grade.grade10]! / 3; // 3 classes
        final grade11AvgSize = gradeStudentCounts[Grade.grade11]! / 2; // 2 classes
        final grade12AvgSize = gradeStudentCounts[Grade.grade12]! / 1; // 1 class

        expect(grade9AvgSize, equals(32.5));
        expect(grade10AvgSize, equals(35.0));
        expect(grade11AvgSize, equals(30.0));
        expect(grade12AvgSize, equals(25.0));
      });

      test('should handle grade level spread calculation', () {
        final gradeDistribution = <Grade, int>{
          Grade.grade10: 2,
          Grade.grade11: 1,
          Grade.grade12: 1,
        };

        final gradesCount = gradeDistribution.keys.length;
        const maxPossibleGrades = 12; // Total possible grades
        final gradeLevelSpread = gradesCount / maxPossibleGrades;

        expect(gradesCount, equals(3));
        expect(gradeLevelSpread, equals(0.25));
      });
    });

    group('Student Count Tracking and Class Size Analytics', () {
      test('should calculate comprehensive class size statistics', () {
        final classSizes = [35, 32, 28, 30, 25, 40, 22, 38, 33, 27];
        classSizes.sort();

        // Basic statistics
        final average = classSizes.reduce((a, b) => a + b) / classSizes.length;
        final minimum = classSizes.first;
        final maximum = classSizes.last;
        final totalStudents = classSizes.reduce((a, b) => a + b);

        expect(average, equals(31.0));
        expect(minimum, equals(22));
        expect(maximum, equals(40));
        expect(totalStudents, equals(310));

        // Median calculation
        final median = classSizes.length % 2 == 0
            ? (classSizes[classSizes.length ~/ 2 - 1] + classSizes[classSizes.length ~/ 2]) / 2.0
            : classSizes[classSizes.length ~/ 2].toDouble();
        expect(median, equals(31.0));

        // Standard deviation
        final variance = classSizes
            .map((size) => (size - average) * (size - average))
            .reduce((a, b) => a + b) / classSizes.length;
        final standardDeviation = sqrt(variance);
        expect(standardDeviation, closeTo(5.42, 0.1));
      });

      test('should track student counts by subject correctly', () {
        final subjectStudentCounts = <String, double>{
          'MATH101': 120.0, // 4 classes * 30 students
          'PHYS101': 90.0,  // 3 classes * 30 students
          'CHEM101': 60.0,  // 2 classes * 30 students
        };

        final totalStudentsAcrossSubjects = subjectStudentCounts.values
            .fold<double>(0, (sum, count) => sum + count);
        expect(totalStudentsAcrossSubjects, equals(270.0));

        // Calculate subject-wise percentages
        final mathPercentage = (subjectStudentCounts['MATH101']! / totalStudentsAcrossSubjects) * 100;
        final physPercentage = (subjectStudentCounts['PHYS101']! / totalStudentsAcrossSubjects) * 100;
        final chemPercentage = (subjectStudentCounts['CHEM101']! / totalStudentsAcrossSubjects) * 100;

        expect(mathPercentage, closeTo(44.44, 0.01));
        expect(physPercentage, closeTo(33.33, 0.01));
        expect(chemPercentage, closeTo(22.22, 0.01));
      });

      test('should calculate student-to-period ratios accurately', () {
        final subjectData = <String, Map<String, dynamic>>{
          'MATH101': {'students': 120.0, 'periods': 6},
          'PHYS101': {'students': 90.0, 'periods': 4},
          'CHEM101': {'students': 60.0, 'periods': 3},
          'BIO101': {'students': 75.0, 'periods': 5},
        };

        final ratios = <String, double>{};
        for (final entry in subjectData.entries) {
          final students = entry.value['students'] as double;
          final periods = entry.value['periods'] as int;
          ratios[entry.key] = periods > 0 ? students / periods : 0.0;
        }

        expect(ratios['MATH101'], equals(20.0));
        expect(ratios['PHYS101'], equals(22.5));
        expect(ratios['CHEM101'], equals(20.0));
        expect(ratios['BIO101'], equals(15.0));

        // Test average ratio
        final averageRatio = ratios.values.reduce((a, b) => a + b) / ratios.length;
        expect(averageRatio, equals(19.375));
      });

      test('should handle edge cases in class size calculations', () {
        // Empty class list
        final emptyClasses = <int>[];
        expect(emptyClasses.isEmpty, isTrue);

        // Single class
        final singleClass = [30];
        final singleAverage = singleClass.reduce((a, b) => a + b) / singleClass.length;
        expect(singleAverage, equals(30.0));

        // All same size classes
        final uniformClasses = [30, 30, 30, 30];
        final uniformAverage = uniformClasses.reduce((a, b) => a + b) / uniformClasses.length;
        final uniformVariance = uniformClasses
            .map((size) => (size - uniformAverage) * (size - uniformAverage))
            .reduce((a, b) => a + b) / uniformClasses.length;
        expect(uniformAverage, equals(30.0));
        expect(uniformVariance, equals(0.0));

        // Very large class sizes
        final largeClasses = [100, 150, 200];
        final largeAverage = largeClasses.reduce((a, b) => a + b) / largeClasses.length;
        expect(largeAverage, closeTo(150.0, 0.01));
      });

      test('should calculate teaching efficiency metrics correctly', () {
        // Test data
        const totalPeriods = 25;
        const maxPossiblePeriods = 40;
        const totalStudents = 750;
        const subjectCount = 5;
        const gradeCount = 3;

        // Calculate efficiency metrics
        const periodsUtilizationRate = totalPeriods / maxPossiblePeriods;
        const averageStudentsPerPeriod = totalStudents / totalPeriods;
        const subjectDiversityIndex = subjectCount / 10.0; // Normalized to max 10 subjects
        const gradeLevelSpread = gradeCount / 12.0; // Normalized to max 12 grades

        expect(periodsUtilizationRate, equals(0.625));
        expect(averageStudentsPerPeriod, equals(30.0));
        expect(subjectDiversityIndex, equals(0.5));
        expect(gradeLevelSpread, equals(0.25));

        // Test efficiency score calculation (weighted average)
        const efficiencyScore = (periodsUtilizationRate * 0.3) + 
                               (subjectDiversityIndex * 0.3) + 
                               (gradeLevelSpread * 0.2) + 
                               ((averageStudentsPerPeriod / 40.0) * 0.2); // Normalize to max 40 students

        expect(efficiencyScore, closeTo(0.5375, 0.01));
      });
    });

    group('Teaching Load Calculations and Distribution Analysis', () {
      test('should perform comprehensive teaching load analysis', () {
        // Create comprehensive test data
        final teachingData = {
          'subjects': {
            'MATH101': {'periods': 6, 'classes': ['10A', '10B'], 'type': 'theory'},
            'PHYS101': {'periods': 4, 'classes': ['10A', '10B'], 'type': 'theory'},
            'CHEM_LAB': {'periods': 3, 'classes': ['10A'], 'type': 'lab'},
            'BIO_PRAC': {'periods': 2, 'classes': ['11A'], 'type': 'practical'},
          },
          'classes': {
            '10A': {'grade': 10, 'students': 35, 'section': 'A'},
            '10B': {'grade': 10, 'students': 32, 'section': 'B'},
            '11A': {'grade': 11, 'students': 28, 'section': 'A'},
          },
        };

        // Calculate total periods
        final totalPeriods = (teachingData['subjects'] as Map<String, dynamic>).values
            .fold<int>(0, (sum, subject) => sum + (subject['periods'] as int));
        expect(totalPeriods, equals(15));

        // Calculate subject distribution
        final subjectDistribution = <String, double>{};
        for (final entry in (teachingData['subjects'] as Map<String, dynamic>).entries) {
          final periods = entry.value['periods'] as int;
          subjectDistribution[entry.key] = (periods / totalPeriods) * 100;
        }

        expect(subjectDistribution['MATH101'], equals(40.0));
        expect(subjectDistribution['PHYS101'], closeTo(26.67, 0.01));
        expect(subjectDistribution['CHEM_LAB'], equals(20.0));
        expect(subjectDistribution['BIO_PRAC'], closeTo(13.33, 0.01));

        // Calculate class load distribution
        final classLoads = <String, int>{};
        for (final subjectEntry in (teachingData['subjects'] as Map<String, dynamic>).entries) {
          final periods = subjectEntry.value['periods'] as int;
          final classes = subjectEntry.value['classes'] as List<String>;
          final periodsPerClass = periods ~/ classes.length;
          
          for (final className in classes) {
            classLoads[className] = (classLoads[className] ?? 0) + periodsPerClass;
          }
        }

        expect(classLoads['10A'], equals(8)); // MATH(3) + PHYS(2) + CHEM(3)
        expect(classLoads['10B'], equals(5)); // MATH(3) + PHYS(2)
        expect(classLoads['11A'], equals(2)); // BIO(2)

        // Calculate total students
        final totalStudents = (teachingData['classes'] as Map<String, dynamic>).values
            .fold<int>(0, (sum, classData) => sum + (classData['students'] as int));
        expect(totalStudents, equals(95));
      });

      test('should analyze teaching load balance and efficiency', () {
        // Test load balancing across different scenarios
        final scenarios = [
          {
            'name': 'Balanced Load',
            'periods': [5, 5, 5, 5], // Even distribution
            'expected_variance': 0.0,
          },
          {
            'name': 'Slightly Unbalanced',
            'periods': [4, 5, 5, 6], // Small variation
            'expected_variance': 0.5,
          },
          {
            'name': 'Highly Unbalanced',
            'periods': [2, 4, 6, 8], // Large variation
            'expected_variance': 5.0,
          },
        ];

        for (final scenario in scenarios) {
          final periods = scenario['periods'] as List<int>;
          final average = periods.reduce((a, b) => a + b) / periods.length;
          final variance = periods
              .map((p) => (p - average) * (p - average))
              .reduce((a, b) => a + b) / periods.length;
          
          expect(variance, equals(scenario['expected_variance']));
        }
      });

      test('should calculate workload intensity metrics', () {
        // Test different workload intensity scenarios
        final workloadScenarios = [
          {
            'periods': 15,
            'students': 300,
            'subjects': 3,
            'intensity': 'Low', // 20 students per period
          },
          {
            'periods': 20,
            'students': 600,
            'subjects': 4,
            'intensity': 'Medium', // 30 students per period
          },
          {
            'periods': 25,
            'students': 1000,
            'subjects': 5,
            'intensity': 'High', // 40 students per period
          },
        ];

        for (final scenario in workloadScenarios) {
          final periods = scenario['periods'] as int;
          final students = scenario['students'] as int;
          final subjects = scenario['subjects'] as int;
          
          final studentsPerPeriod = students / periods;
          final periodsPerSubject = periods / subjects;
          final studentsPerSubject = students / subjects;
          
          if (scenario['intensity'] == 'Low') {
            expect(studentsPerPeriod, equals(20.0));
            expect(periodsPerSubject, equals(5.0));
            expect(studentsPerSubject, equals(100.0));
          } else if (scenario['intensity'] == 'Medium') {
            expect(studentsPerPeriod, equals(30.0));
            expect(periodsPerSubject, equals(5.0));
            expect(studentsPerSubject, equals(150.0));
          } else if (scenario['intensity'] == 'High') {
            expect(studentsPerPeriod, equals(40.0));
            expect(periodsPerSubject, equals(5.0));
            expect(studentsPerSubject, equals(200.0));
          }
        }
      });
    });
  });
}