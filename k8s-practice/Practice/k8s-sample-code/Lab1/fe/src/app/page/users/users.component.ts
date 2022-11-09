import { Component, OnInit } from '@angular/core';
import { User } from '../../model/user.model';
import { UserService } from 'src/app/service/user.service';

@Component({
  selector: 'app-users',
  templateUrl: './users.component.html',
  styleUrls: [
    './users.component.css',
    './styles/vendor/bootstrap/css/bootstrap.min.css',
    './styles/fonts/font-awesome-4.7.0/css/font-awesome.min.css',
    './styles/vendor/animate/animate.css',
    './styles/vendor/select2/select2.min.css',
    './styles/vendor/perfect-scrollbar/perfect-scrollbar.css',
    './styles/css/util.css',
    './styles/css/main.css'
  ]
})
export class UsersComponent implements OnInit {
  users: User[] = [];

  constructor(private userService: UserService) { }

  ngOnInit(): void {
    this.userService.getUsers().subscribe(
      data => {
        this.users = data
      }
    );
  }

}
