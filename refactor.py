import os
import glob

lib_dir = 'lib'

# Files in lib
main_file = os.path.join(lib_dir, 'main.dart')
with open(main_file, 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace("'main_navigation_screen.dart'", "'screens/main_navigation_screen.dart'")
content = content.replace("'login_screen.dart'", "'screens/login_screen.dart'")
with open(main_file, 'w', encoding='utf-8') as f:
    f.write(content)

# Files in lib/screens
screen_files = glob.glob(os.path.join(lib_dir, 'screens', '*.dart'))
for sf in screen_files:
    with open(sf, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace old file imports with new paths or remove if unused
    content = content.replace("'api_service.dart'", "'../services/auth_service.dart';\nimport '../services/course_service.dart'")
    content = content.replace("'models.dart'", "'../models/course_model.dart';\nimport '../models/user_profile_model.dart'")
    content = content.replace("import 'sample_data.dart';\n", "")
    content = content.replace("'course_detail_screen.dart'", "'course_details_screen.dart'")
    content = content.replace("'courses_screen.dart'", "'course_list_screen.dart'")
    
    # Replace references inside code
    content = content.replace("ApiService.login", "AuthService.login")
    content = content.replace("ApiService.register", "AuthService.register")
    content = content.replace("ApiService.changePassword", "AuthService.changePassword")
    content = content.replace("ApiService.getCurrentUser", "AuthService.getCurrentUser")
    content = content.replace("ApiService.saveAuthData", "AuthService.saveAuthData")
    content = content.replace("ApiService.clearAuthData", "AuthService.clearAuthData")
    
    content = content.replace("ApiService.searchCourses", "CourseService.searchCourses")
    content = content.replace("ApiService.getCourseDetails", "CourseService.getCourseDetails")
    content = content.replace("ApiService.getRecommendedCourses", "CourseService.getRecommendedCourses")
    content = content.replace("ApiService.getMyCourses", "CourseService.getMyCourses")
    content = content.replace("ApiService.buyCourse", "CourseService.buyCourse")
    content = content.replace("ApiService.rateCourse", "CourseService.rateCourse")
    
    content = content.replace("CourseDetailScreen", "CourseDetailsScreen")
    content = content.replace("CoursesScreen", "CourseListScreen")
    content = content.replace("courses_screen", "course_list_screen")
    content = content.replace("course_detail_screen", "course_details_screen")

    with open(sf, 'w', encoding='utf-8') as f:
        f.write(content)

print('Done')
