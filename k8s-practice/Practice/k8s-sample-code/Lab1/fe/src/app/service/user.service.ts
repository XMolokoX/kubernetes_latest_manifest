import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { environment } from 'src/environments/environment';
import { User } from '../model/user.model';


@Injectable({
    providedIn: "root"
})

export class UserService {
    header: HttpHeaders = new HttpHeaders();
    beURL: string = environment.beURL;

    constructor(private http: HttpClient) {
        this.header = this.header.append('Content-Type', 'application/json');
    }

    getUsers() {
        return this.http.get<User[]>(this.beURL + "/users", { headers: this.header });
    }
}