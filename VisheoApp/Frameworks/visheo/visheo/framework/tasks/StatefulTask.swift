
//
//  FailableTask.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 11/19/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//


enum TaskState: Int
{
	case blocked = -1
	case pending = 1
	case running = 2
	case finished = 3
}


protocol StatefulTask
{
	var state: TaskState { get set }
}
