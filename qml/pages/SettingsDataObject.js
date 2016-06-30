/*
 * Copyright (C) 2016 Jens Drescher, Germany
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

.pragma library

//Need this tables here as helpers. They are used from the SettingsPage(s).
//Stupid QML arrays can't do anything, they suck big time!!! You can't even change values on runtime, what are they good for?
var arPIDarray = [{text: qsTr("Empty"), pid: "0000", index: 0}];
var arLookupPID = {};
var arLookupINDEX = {};
