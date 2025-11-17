package com.Employees.EmployeeApp.Repository;

import com.Employees.EmployeeApp.Entity.Employee;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EmployeeRepository extends JpaRepository<Employee, Long> {
}
